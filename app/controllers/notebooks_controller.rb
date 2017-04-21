# Notebooks controller
class NotebooksController < ApplicationController
  collection_methods = [ # rubocop: disable Lint/UselessAssignment
    :index,
    :stars,
    :suggested
  ]
  member_readers_anonymous = %i[
    show
    download
    uuid
    friendly_url
    wordcloud
  ]
  member_readers_login = %i[
    similar
    metrics
    metadata
    shares
    star?
    star=
    public?
    owner
    title
    tags
    tags=
    description
    feedback
    diff
  ]
  member_readers = member_readers_anonymous + member_readers_login
  member_editors = %i[
    edit
    update
    destroy
    shares=
    public=
    owner=
    title=
    description=
  ]
  member_methods = member_readers + member_editors + [:create]

  # Must be logged in except for browsing notebooks
  before_action(
    :verify_login,
    only: member_methods - member_readers_anonymous + %i[stars suggested]
  )

  # Set @notebook for member endpoints (but not :create)
  before_action :set_notebook, only: member_readers + member_editors

  # Set @stage for new uploads and edits
  before_action :set_stage, only: %i[create update]

  # Must be able to view @notebook for non-modifying endpoints
  before_action :verify_read_or_admin, only: member_readers

  # Must be able to edit @notebook for modifying endpoints
  before_action :verify_edit_or_admin, only: member_editors

  # Must accept terms when uploading/updating @notebook
  before_action :verify_accepted_terms, only: %i[create update]


  #########################################################
  # Primary member endpoints
  #########################################################

  # GET /notebooks/:uuid
  def show
    clickstream('viewed notebook', tracking: ref_tracking)
  end

  # POST /notebooks
  def create
    # Clean metadata params
    params[:title].strip!
    params[:description].strip!

    # Check existence: (owner, title) must be unique
    @owner = determine_owner
    @notebook = Notebook.find_or_initialize_by(
      owner: @owner,
      title: Notebook.groom(params[:title])
    )
    @new_record = @notebook.new_record?
    @old_content = @new_record ? nil : @notebook.content
    if !@new_record && !params[:overwrite].to_bool
      raise Notebook::BadUpload, 'duplicate title; choose another or select overwrite'
    end

    # Parse, validate, prep for storage
    @tags = parse_tags
    populate_notebook

    # Save the content and db record.
    success = @new_record ? save_new : save_update
    if success
      UsersAlsoView.compute(@notebook.id)
      render(
        json: { uuid: @notebook.uuid, friendly_url: @notebook.friendly_url },
        status: (@new_record ? :created : :ok)
      )
    else
      render json: @notebook.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /notebooks/:uuid
  def update
    # Parse, validate, prep for storage
    @old_content = @notebook.content
    @tags = parse_tags
    populate_notebook

    # Save the content and db record.
    if save_update
      render json: { uuid: @notebook.uuid, friendly_url: @notebook.friendly_url }
    else
      render json: @notebook.errors, status: :unprocessable_entity
    end
  end

  # DELETE /notebooks/:uuid
  def destroy
    commit_message = "#{@user.user_name}: [delete] #{@notebook.title}"
    RemoteStorage.remove_file(@notebook.basename, public: @notebook.public, message: commit_message)
    @notebook.destroy
    head :no_content
  end


  #########################################################
  # Other member endpoints
  #########################################################

  # GET /notebooks/:uuid/similar
  def similar
    similar = @notebook.notebook_similarities.map do |sim|
      [sim.other_notebook.uuid, sim.score]
    end
    render json: similar.to_h
  end

  # GET /notebooks/:uuid/metrics
  def metrics
    respond_to do |format|
      format.html do
        @unique_viewers = @notebook.unique_viewers
        @unique_runners = @notebook.unique_runners
        @edit_history = @notebook.edit_history.to_a
        @more_like_this = @notebook.more_like_this(@user, count: 10).to_a
        @users_also_viewed = @notebook.users_also_viewed(@user).limit(10).map(&:other_notebook).to_a
        @stars = @notebook.stars.to_a
        @executions_by_day = execution_success_chart(@notebook, 'DATE(executions.updated_at)', :day)
        @executions_by_cell = execution_success_chart(@notebook, 'code_cells.cell_number', :cell_number)
        @runtime_by_cell = @notebook
          .executions
          .joins(:code_cell)
          .where('executions.updated_at > ?', 30.days.ago)
          .select('AVG(runtime) AS runtime, code_cells.cell_number')
          .group('cell_number')
          .map {|e| [e.cell_number, e.runtime]}
        @runtime_by_cell = GalleryLib.chart_prep(
          @runtime_by_cell,
          keys: (0...@notebook.code_cells.count)
        )
        render 'notebook_metrics'
      end
      format.json do
        render json: @notebook.metrics
      end
    end
  end

  # GET /notebooks/:uuid/metadata
  def metadata
    meta = {}
    Notebook.attribute_names.each do |attr|
      case attr
      when 'owner_id'
        meta[:owner] = @notebook.owner_id_str
      when 'creator_id'
        meta[:creator] = @notebook.creator.user_name
      when 'updater_id'
        meta[:updater] = @notebook.updater.user_name
      else
        meta[attr.to_sym] = @notebook.send(attr)
      end
    end
    meta[:tags] = @notebook.tags.pluck(:tag).join(',')
    meta[:url] = @notebook.friendly_url
    render json: meta
  end

  # GET /notebooks/:uuid/download
  def download
    if params.include?(:run)
      clickstream('ran notebook', tracking: ref_tracking)
    else
      clickstream('downloaded notebook', tracking: ref_tracking)
    end

    # Insert a few things into the content when downloaded
    jn = @notebook.notebook
    jn['metadata'] = {} unless jn.include?('metadata')
    jn['metadata']['gallery'] = {} # clear out anything there
    if @user.can_edit?(@notebook)
      jn['metadata']['gallery']['link'] = @notebook.uuid
    else
      jn['metadata']['gallery']['clone'] = @notebook.uuid
    end
    jn['metadata']['gallery']['commit'] = @notebook.commit_id

    send_data(jn.to_json, filename: "#{@notebook.title}.ipynb")
  end

  # GET /notebooks/:uuid/shares
  def shares
    render json: { shares: @notebook.shares.pluck(:user_name) }
  end

  # PATCH /notebooks/:uuid/shares
  def shares=
    old_shares = @notebook.shares.pluck(:user_name)
    new_shares =
      if params[:shares].is_a? Array
        params[:shares]
      else
        params[:shares].parse_csv.map(&:strip) rescue []
      end
    # Remove share for deleted usernames
    to_destroy = []
    @notebook.shares.each do |user|
      to_destroy << user unless new_shares.include?(user.user_name)
    end
    to_destroy.each {|user| @notebook.shares.destroy(user)}

    # Add share for new usernames
    members = []
    member_emails = []
    non_members = []
    (new_shares - old_shares).each do |user_name|
      user = User.find_by(user_name: user_name)
      if user
        members << user_name
        member_emails << user.email
        @notebook.shares << user
        clickstream('shared notebook', tracking: user_name)
      else
        non_members << user_name
      end
    end

    # Email newly shared-with members
    unless members.empty?
      NotebookMailer.share(
        @notebook,
        @user,
        member_emails,
        params[:message],
        request.base_url
      ).deliver_later
    end

    # Attempt to share with non-members (extendable)
    unless non_members.empty?
      NonmemberShare.share(
        @notebook,
        @user,
        non_members,
        params[:message],
        request.base_url
      )
    end

    render json: {
      shares: @notebook.shares.pluck(:user_name),
      non_members: non_members
    }
  end

  # GET /notebooks/:uuid/star
  def star?
    render json: { star: @user.stars.include?(@notebook) }
  end

  # PATCH /notebooks/:uuid/star
  def star=
    old_status = @user.stars.include?(@notebook)
    new_status = params[:star].to_bool
    if old_status != new_status
      if new_status
        @user.stars << @notebook
      else
        @user.stars.destroy(@notebook)
      end
    end
    render json: { star: new_status }
  end

  # GET /notebooks/:uuid/public
  def public?
    render json: { public: @notebook.public }
  end

  # PATCH /notebooks/:uuid/public
  def public=
    old_status = @notebook.public
    new_status = params[:public].to_bool
    if old_status != new_status
      @notebook.public = new_status
      @notebook.save!
      status_str = new_status ? 'public' : 'private'
      message = "#{@user.user_name}: [made #{status_str}] #{@notebook.title}"
      RemoteStorage.remove_file(@notebook.basename, public: old_status, message: message)
      RemoteStorage.create_file(@notebook.basename, @notebook.content, public: new_status, message: message)
      clickstream("made notebook #{status_str}")
    end
    render json: { public: @notebook.public }
  end

  # GET /notebooks/:uuid/owner
  def owner
    render json: { owner: @notebook.owner_id_str }
  end

  # PATCH /notebooks/:uuid/owner
  def owner=
    @notebook.owner =
      if params[:owner].start_with?('group:')
        gid = params[:owner][6..-1]
        Group.find_by!(gid: gid)
      else
        User.find_by!(user_name: params[:owner])
      end
    @notebook.save!
    render json: { owner: params[:owner] }
  end

  # GET /notebooks/:uuid/title
  def title
    render json: { title: @notebook.title }
  end

  # PATCH /notebooks/:uuid/title
  def title=
    exists = Notebook.find_by(
      owner: @notebook.owner,
      title: Notebook.groom(params[:title])
    )
    if exists && exists.uuid != @notebook.uuid
      raise Notebook::BadUpload, 'duplicate title of notebook with same owner'
    end
    @notebook.title = params[:title]
    @notebook.save!
    render json: { title: @notebook.title }
  end

  # GET /notebooks/:uuid/tags
  def tags
    render json: { tags: @notebook.tags.pluck(:tag) }
  end

  # PATCH /notebooks/:uuid/tags
  def tags=
    tags = Tag.from_csv(params[:tags], user: @user, notebook: @notebook)
    tags.each do |tag|
      raise Notebook::BadUpload.new('bad tag', tag.errors) if tag.invalid?
    end

    @notebook.tags = tags
    @notebook.save!
    render json: { tags: @notebook.tags.pluck(:tag) }
  end

  # GET /notebooks/:uuid/description
  def description
    render json: { description: @notebook.description }
  end

  # PATCH /notebooks/:uuid/description
  def description=
    @notebook.description = params[:description]
    @notebook.save!
    render json: { description: @notebook.description }
  end

  # GET /notebooks/:uuid/uuid
  def uuid
    render json: { uuid: @notebook.uuid }
  end

  # GET /notebooks/:uuid/friendly_url
  def friendly_url
    render json: { friendly_url: request.base_url + @notebook.friendly_url }
  end

  # POST /notebooks/:uuid/feedback
  def feedback
    feedback = Feedback.new(
      user: @user,
      notebook: @notebook,
      ran: params[:ran].nil? ? nil : params[:ran].to_bool,
      worked: params[:worked].nil? ? nil : params[:worked].to_bool,
      broken_feedback: params[:broken_feedback],
      general_feedback: params[:general_feedback]
    )
    feedback.save!
    NotebookMailer.feedback(feedback, request.base_url).deliver_later
    head :no_content
  end

  # GET /notebooks/:uuid/wordcloud.png
  def wordcloud
    file = @notebook.wordcloud_image_file
    raise NotFound, 'wordcloud not generated yet' unless File.exist?(file)
    send_file(file, disposition: 'inline')
  end

  # POST /notebooks/:uuid/diff
  def diff
    file = request.body.read
    jn = JupyterNotebook.new(file)
    diff = GalleryLib::Diff.all_the_diffs(@notebook.notebook.text_for_diff, jn.text_for_diff)
    render json: diff
  end


  #########################################################
  # Collection endpoints
  #########################################################

  # GET /notebooks
  def index
    @notebooks = query_notebooks
    @tags = []
    @groups = []
    return if params[:q].blank?

    # If there are search terms, get tag and group results too
    words = params[:q].split.reject {|w| w.start_with? '-'}
    @tags = Tag.readable_by(@user, words)
    ids = Group.search_ids do
      fulltext(params[:q])
    end
    @groups = Group.readable_by(@user).select {|group, _count| ids.include?(group.id)}
  end

  # GET /notebooks/stars
  def stars
    @notebooks = query_notebooks.where(id: @user.stars.map(&:id))
    render 'index'
  end

  # GET /notebooks/examples
  def examples
    @notebooks = @user.trusted
  end

  # GET /notebooks/recommended
  def recommended
    # Only show one page of recommended notebooks.
    # We'd like to show a couple random recommendations, so if there are more
    # than a page's worth of recommendations, delete some out of the middle.
    @notebooks = @user.notebook_recommendations.order('score DESC').to_a
    if @notebooks.count > Notebook.per_page
      random = @notebooks.select {|nb| nb.reasons.start_with?('randomly')}
      take_random = [random.count, 2].min
      @notebooks = @notebooks.take(Notebook.per_page - take_random) + random.last(take_random)
    end
    @tags = @user.tag_recommendations(10)
    @groups = @user.group_recommendations(10)
  end

  # GET /notebooks/shared_with_me
  def shared_with_me
    @notebooks = @user.shares.paginate(page: @page)
  end

  # GET /notebooks/learning
  def learning
    @notebook = Notebook.find_by!(uuid: GalleryConfig.learning.landing)
  end


  #########################################################
  # Private helper methods
  #########################################################

  protected

  # Get the notebook
  def set_notebook
    notebook_from_partial_uuid(params[:id])
  end

  private

  # Get the staged notebook
  def set_stage
    @stage = Stage.find_by!(uuid: params[:staging_id])
    verify_stage_access
    @jn = @stage.notebook
  end

  # Save bits of Referer and internal 'ref' for clickstream
  def ref_tracking
    tracking = (request.headers['Referer'] || '').sub(request.base_url, '')[0...150]
    if params[:ref].present?
      tracking += ' ' unless tracking.empty?
      tracking += "(#{params[:ref]})"
    end
    tracking
  end

  # Verify that the user is the one that staged the notebook.
  def verify_stage_access
    allowed = (@stage.user == @user || @user.admin?)
    message = "you are not authorized for stage #{params[:staging_id]}"
    raise User::Forbidden, message unless allowed
  end

  # Figure out the owner object for new notebooks
  def determine_owner
    if params[:owner] && params[:owner].start_with?('group:')
      # Group id specified - check user is an editor
      gid = params[:owner][6..-1]
      group = Group.find_by(gid: gid)
      unless group.editors.include?(@user)
        message = "you are not an editor in group #{group.gid} (#{group.name})"
        raise User::Forbidden, message
      end
      group
    else
      @user
    end
  end

  # Parse tags param and validate
  def parse_tags
    tags = Tag.from_csv(params[:tags], user: @user, notebook: @notebook)
    tags.each do |tag|
      raise Notebook::BadUpload.new('bad tag', tag.errors) if tag.invalid?
    end
    tags
  end

  # Populate/update the notebook object.
  def populate_notebook
    # Fields to always set.
    # Note that if overwriting an existing notebook, we ignore public/private
    # in params (i.e. you can't overwrite a public notebook with a private one)
    @notebook.lang, @notebook.lang_version = @jn.language
    @notebook.description = params[:description] if params[:description].present?
    @notebook.updater = @user

    # Fields for new notebooks only
    if @new_record
      @notebook.uuid = params[:staging_id]
      @notebook.title = params[:title]
      @notebook.public = !params[:private].to_bool
      @notebook.creator = @user
      @notebook.owner = @owner
    end

    # Fields defined by extensions
    set_notebook_extension_fields

    # Check validity of the notebook content.
    # This is not done at stage time because validations may depend on
    # user/notebook metadata or request parameters.
    raise Notebook::BadUpload.new('bad content', @jn.errors) if @jn.invalid?(@notebook, @user, params)

    # Check validity - we want to be as sure as possible that the DB records
    # will save before we start storing the content anywhere.
    raise Notebook::BadUpload.new('invalid parameters', @notebook.errors) if @notebook.invalid?
  end

  # Set notebook fields defined in extensions
  def set_notebook_extension_fields
    Notebook.extension_attributes.each do |attr|
      @notebook.send("#{attr}=".to_sym, params[attr]) if params[attr]
    end
  end

  # Save new/updated notebook to remote storage
  def save_stage_to_remote(message)
    if @old_content == @stage.content
      # Nothing to do
      'no changes'
    else
      method = @new_record ? :create_file : :edit_file
      RemoteStorage.send(method, @notebook.basename, @stage.content, public: @notebook.public, message: message)
    end
  end

  # Save a new notebook to cache and remote storage
  def save_new
    # We try saving to remote storage first, because we don't want to update
    # the db or our local cache if that fails.

    # The commit_id field is used by jupyter-docker to detect changes.  However,
    # the jupyter image only sees the result of the intial staging, so we use
    # the staging id instead of the real commit id from remote storage.  The
    # real commit id from remote will go into clickstream log.
    @notebook.commit_id = params[:staging_id]
    commit_message = "#{@user.user_name}: [new] #{@notebook.title}\n#{@notebook.description}"
    real_commit_id = save_stage_to_remote(commit_message) || @notebook.uuid

    # Now save to the db and to local cache
    @notebook.tags = @tags
    @notebook.content = @stage.content # saves to cache
    if @notebook.save
      @stage.destroy
      clickstream('agreed to terms')
      clickstream('created notebook', tracking: real_commit_id)
      true
    else
      # We checked validity before saving, so we don't expect to land here, but
      # if we do, we need to rollback the content storage.
      @notebook.remove_content
      RemoteStorage.remove_file(
        @notebook.basename,
        public: @notebook.public,
        message: 'rollback due to error'
      )
      false
    end
  end

  # Save an updated notebook to cache and remote storage
  def save_update
    # See comments in #save_new for general strategy

    # Save to remote first
    @notebook.commit_id = params[:staging_id]
    commit_message = "#{@user.user_name}: [edit] #{@notebook.title}"
    real_commit_id = save_stage_to_remote(commit_message) || @notebook.uuid

    # Now save to db and local cache
    @notebook.tags = @tags
    @notebook.content = @stage.content # saves to cache
    if @notebook.save
      @stage.destroy
      clickstream('agreed to terms')
      clickstream('edited notebook', tracking: real_commit_id)
      true
    else
      # Rollback content storage
      @notebook.content = @old_content
      RemoteStorage.edit_file(
        @notebook.basename,
        @old_content,
        public: @notebook.public,
        message: 'rollback due to error'
      )
      false
    end
  end
end
