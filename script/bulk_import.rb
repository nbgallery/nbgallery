# To run this script: rails runner script/bulk_import.rb

def stage_notebook(filename)
  content = File.read(filename)

  @jn = JupyterNotebook.new(content)

  @jn.strip_output!
  @jn.strip_gallery_meta!

  staging_id = SecureRandom.uuid
  @stage = Stage.new(uuid: staging_id, user: @user)
  if @stage.save
    @stage.content = @jn.pretty_json
    @params[:staged] = staging_id
    @params[:staging_id] = staging_id
    return true
  else
    return false
  end
end

def save_new
  @notebook.commit_id = @params[:staging_id]
  commit_message = "#{@user.user_name}: [new] #{@notebook.title}\n#{@notebook.description}"
  # Save to the db and to local cache
  @notebook.tags = []
  @notebook.content = @stage.content # saves to cache
  if @notebook.save
    @stage.destroy
    real_commit_id = Revision.notebook_create(@notebook, @user, commit_message)
    return true
  else
    # We checked validity before saving, so we don't expect to land here, but
    # if we do, we need to rollback the content storage.
    @notebook.remove_content
    return false
  end
end

def create_notebook(filename,overwrite)
  @params[:title] = filename.gsub(/.*\//,'').gsub('.ipynb','').gsub('_',' ').strip
  @params[:description] = "Automatic Upload"
  nb=JSON.parse(File.read(filename))
  nb["cells"].each do | cell |
    if (cell["cell_type"]=="markdown")
      source=cell["source"].join()
      #attempt to get rid of headings from the cell
      source=source.gsub(/^.*?\n=+\n?/,'')
      if(source.length>20)
        @params[:description] = source[0..250]
        if(source.length>250)
          @params[:description] = @params[:description] + "..."
        end
        break
      end
    end
  end


  # Check existence: (owner, title) must be unique
  @notebook = Notebook.find_or_initialize_by(
    owner: @owner,
    title: Notebook.groom(@params[:title])
  )
  @new_record = @notebook.new_record?
  @old_content = @new_record ? nil : @notebook.content
  if !@new_record && !overwrite.to_bool
    raise Notebook::BadUpload, 'Duplicate title; choose another or select overwrite.'
  end

  # Parse, validate, prep for storage
  @notebook.lang, @notebook.lang_version = @jn.language
  @notebook.description = @params[:description] if @params[:description].present?
  @notebook.updater = @user

  # Fields for new notebooks only
  if @new_record
    @notebook.uuid = @params[:staging_id]
    @notebook.title = @params[:title]
    @notebook.public = !@params[:private].to_bool
    @notebook.creator = @user
    @notebook.owner = @owner
  end

  # Check validity of the notebook content.
  # This is not done at stage time because validations may depend on
  # user/notebook metadata or request parameters.
  raise Notebook::BadUpload.new('bad content', @jn.errors) if @jn.invalid?(@notebook, @user, @params)

  # Check validity - we want to be as sure as possible that the DB records
  # will save before we start storing the content anywhere.
  raise Notebook::BadUpload.new('invalid parameters', @notebook.errors) if @notebook.invalid?

  # Save the content and db record.
  success = @new_record ? save_new : false
  if success
    UsersAlsoView.initial_upload(@notebook, @user) if @new_record
    @notebook.thread.subscribe(@user)
    return true
  else
    print @notebook.errors
    return false
  end
end

loop do
  print 'Enter username for Notebook Creator (leave blank to exit):'
  username = gets.strip
  if(username.length == 0)
    exit!
  end
  @user = User.find_by(user_name: username)
  if(@user)
    print "Found user " + username + "\n"
    break
  else
    print "\nUser " + username + " not found\n"
  end
end
loop do
  print 'Enter user or group name for Notebook owner (Leave blank to use creator): '
  ownername = gets.strip
  if(ownername)
    @owner = User.find_by(user_name: ownername)
    if(@owner)
      print "Found user "+ownername+"\n"
      break
    else
      @owner = Group.find_by(name: ownername)
      if(@owner)
        print "Found Group "+ownername+"\n"
        break
      else
        print "\nUser or Group "+ownername+" not found\n"
      end
    end
  else
    @owner=@user
    break
  end
end

print "Enter path for Notebooks:"
path = gets.strip
@params = {}

print "Searching for .ipynb files in " + path + "\n"
Dir.glob(path + '/*.ipynb') do | filename |
  print filename + "\n"
  if stage_notebook(filename)
    if create_notebook(filename,false)
      print "Notebook Created "+filename+"\n"
    else
      print "Errors Creating Notebook "+filename+"\n"
    end
  else
    print "Unable to create Notebook "+filename+"\n"
  end
end
Notebook.reindex
