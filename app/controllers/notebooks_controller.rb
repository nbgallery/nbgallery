# Notebooks controller
class NotebooksController < ApplicationController
  collection_methods = [ # rubocop: disable Lint/UselessAssignment
    :index,
    :stars,
    :suggested,
    :recently_executed
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
    users
    reviews
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
    submit_for_review
    deprecate
    remove_deprecation_status
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

  # Check if non admins can submit reviews
  before_action :verify_admin, only: :submit_for_review,
    unless: ->  { GalleryConfig.user_permissions.propose_review }

  #########################################################
  # Primary member endpoints
  #########################################################

  # GET /notebooks/:uuid
  def show
    if request.format.html?
      commontator_thread_show(@notebook)
      clickstream('viewed notebook', tracking: ref_tracking)
    else
      redirect_to download_notebook_path(@notebook), status: :moved_permanently
    end
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
      raise Notebook::BadUpload, 'Duplicate title; choose another or select overwrite.'
    end

    # Parse, validate, prep for storage
    @tags = parse_tags
    populate_notebook

    # Save the content and db record.
    success = @new_record ? save_new : save_update
    if success
      UsersAlsoView.initial_upload(@notebook, @user) if @new_record
      @notebook.thread.subscribe(@user)
      render(
        json: { uuid: @notebook.uuid, friendly_url: notebook_path(@notebook) },
        status: (@new_record ? :created : :ok)
      )
      flash[:success] = "Notebook created successfully."
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
      @notebook.thread.subscribe(@user)
      render json: { uuid: @notebook.uuid, friendly_url: notebook_path(@notebook) }
      flash[:success] = "Notebook has been updated successfully."
    else
      render json: @notebook.errors, status: :unprocessable_entity
    end
  end

  # DELETE /notebooks/:uuid
  def destroy
    commit_message = "#{@user.user_name}: [delete] #{@notebook.title}"
    @notebook.thread.destroy # workaround for commontator 4
    @notebook.destroy
    Revision.notebook_delete(@notebook, @user, commit_message)
    flash[:success] = "Notebook has been deleted successfully."
    redirect_to user_path(@user)
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
        @revisions = @notebook.revision_map(@user)
        @more_like_this = @notebook.more_like_this(@user, count: 10)
        @users_also_viewed = @notebook.users_also_viewed(@user).limit(10).map(&:other_notebook)
        @stars = @notebook.stars.to_a
        @executions_by_day = execution_success_chart(@notebook, 'DATE(executions.updated_at)', :day)
        @executions_by_cell = execution_success_chart(@notebook, 'code_cells.cell_number', :cell_number)
        @runtime_by_cell = GalleryLib.chart_prep(
          @notebook.runtime_by_cell,
          keys: (0...@notebook.code_cells.count)
        )
        @health_status = @notebook.health_status
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
    meta[:owner_name] = @notebook.owner.name
    meta[:owner_url] = url_for(@notebook.owner)
    meta[:tags] = @notebook.tags.pluck(:tag).join(',')
    meta[:url] = url_for(@notebook)
    revision = @notebook.revisions.last
    meta[:git_commit_id] = revision.commit_id if revision
    render json: meta
  end

  # GET /notebooks/:uuid/users
  def users
    cleaner = ->(h) {h.map {|k, v| [k.user_name, { org: k.org, count: v[:count], last: v[:last] }]}.to_h}
    users = {
      viewers: cleaner.call(@notebook.unique_viewers),
      runners: cleaner.call(@notebook.unique_runners),
      executors: cleaner.call(@notebook.unique_executors),
      downloaders: cleaner.call(@notebook.unique_downloaders)
    }
    render json: users
  end

  # GET /notebooks/:uuid/download
  def download
    unless params[:clickstream] == 'false'
      if params.include?(:run)
        clickstream('ran notebook', tracking: ref_tracking)
      else
        clickstream('downloaded notebook', tracking: ref_tracking)
      end
    end

    # Insert a few things into the content when downloaded
    jn = @notebook.notebook
    jn['metadata'] ||= {}
    gallery = jn['metadata']['gallery'] ||= {}
    gallery['uuid'] = @notebook.uuid
    if @user.can_edit?(@notebook)
      gallery['link'] = @notebook.uuid
      gallery.delete('clone')
    else
      gallery['clone'] = @notebook.uuid
      gallery.delete('link')
    end
    gallery['commit'] = @notebook.commit_id
    gallery['gallery_url'] = request.base_url
    revision = @notebook.revisions.last
    gallery['git_commit_id'] = revision.commit_id if revision

    send_data(jn.to_json, filename: "#{@notebook.title}.ipynb")
  end

  # GET /notebooks/:uuid/shares
  def shares
    render json: { shares: @notebook.shares.pluck(:user_name) }
  end

  # PATCH /notebooks/:uuid/shares
  def shares=
    to_remove, to_add, non_member_emails, errors = share_params

    # Check for invalid shares
    unless errors.empty?
      response = {
        message: 'shares must be valid users or fully-qualified email addresses',
        errors: errors
      }
      render json: response, status: :unprocessable_entity
      return
    end

    # Remove share for deleted usernames
    to_remove.each {|user| @notebook.shares.destroy(user)}

    # Add share for new usernames
    to_add.each do |user|
      @notebook.shares << user
      clickstream('shared notebook', tracking: user.user_name)
    end
    unless to_add.empty?
      NotebookMailer.share(
        @notebook,
        @user,
        to_add.map(&:email),
        params[:message],
        request.base_url
      ).deliver_later
    end

    # Attempt to share with non-members (extendable)
    unless non_member_emails.empty?
      NonmemberShare.share(
        @notebook,
        @user,
        non_member_emails,
        params[:message],
        request.base_url
      )
    end

    render json: {
      shares: @notebook.shares.pluck(:user_name),
      non_members: non_member_emails
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
      Revision.notebook_metadata(@notebook, @user)
      clickstream("made notebook #{status_str}")
      flash[:success] = "Successfully made this notebook #{status_str}."
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
    if @notebook.save
      if params[:owner].start_with?('group:')
        flash[:success] = "Owner of notebook has been set to group: \"#{Group.find_by!(gid: params[:owner][6..-1]).name}\" successfully."
      else
        user = User.find_by!(user_name: params[:owner])
        flash[:success] = "Owner of notebook has been set to #{user.first_name} #{user.last_name} successfully."
      end
      render json: { owner: @notebook.owner_id_str }
    else
      render json: @notebook.errors, status: :unprocessable_entity
    end
  end

  # GET /notebooks/:uuid/filter_owner
  def filter_owner
    respond_to do |format|
      format.html {render :partial => 'notebooks/ownership_autocomplete', :locals => {:query => params[:query]}}
    end
  end

  # GET /notebooks/:uuid/autocomplete_notebooks
  def autocomplete_notebooks
    respond_to do |format|
      format.html {render :partial => 'notebooks/notebooks_autocomplete', :locals => {:query => params[:query]}}
    end
  end

  # GET /notebooks/:uuid/title
  def title
    render json: { title: @notebook.title }
  end

  # PATCH /notebooks/:uuid/title
  def title=
    new_title = (params[:title] || '').strip
    exists = Notebook.find_by(
      owner: @notebook.owner,
      title: Notebook.groom(new_title)
    )
    duplicate = exists && exists.uuid != @notebook.uuid
    raise Notebook::BadUpload, 'duplicate title of notebook with same owner' if duplicate
    @notebook.title = new_title
    @notebook.save!
    render json: { title: @notebook.title }
    flash[:success] = "Notebook title has been updated successfully."
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
    flash[:success] = "Notebook tags have been updated successfully."
  end

  # GET /notebooks/:uuid/description
  def description
    render json: { description: @notebook.description }
  end

  # PATCH /notebooks/:uuid/description
  def description=
    @notebook.description = (params[:description] || '').strip
    @notebook.save!
    render json: { description: @notebook.description }
    flash[:success] = "Notebook description has been updated successfully."
  end

  # GET /notebooks/:uuid/uuid
  def uuid
    render json: { uuid: @notebook.uuid }
  end

  # GET /notebooks/:uuid/friendly_url
  def friendly_url
    render json: { friendly_url: url_for(@notebook) }
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

  # POST /notebooks/:id/submit_for_review
  def submit_for_review
    comments = "Submitted by #{@user.name}: \"#{params[:comments]}\""
    count_created = 0
    reviews_that_already_exist = 0
    if params[:technical] == "yes"
      if @notebook.revisions.last != nil
        if (Review.where(notebook_id: @notebook.id, revision_id: @notebook.revisions.last.id, revtype: "technical").count == 0)
          Review.create(:notebook_id => @notebook.id, :revision_id => @notebook.revisions.last.id, :revtype => "technical", :status => "queued", :comments => comments)
          count_created += 1
        elsif (Review.where(notebook_id: @notebook.id, revision_id: @notebook.revisions.last.id, revtype: "technical").count > 0)
          reviews_that_already_exist += 1
        end
      else
        if (Review.where(notebook_id: @notebook.id, revtype: "technical").count == 0)
          Review.create(:notebook_id => @notebook.id, :revtype => "technical", :status => "queued", :comments => comments)
          count_created += 1
        elsif (Review.where(notebook_id: @notebook.id, revtype: "technical").count > 0)
          reviews_that_already_exist += 1
        end
      end
    end
    if params[:functional] == "yes"
      if @notebook.revisions.last != nil
        if (Review.where(notebook_id: @notebook.id, revision_id: @notebook.revisions.last.id, revtype: "functional").count == 0)
          Review.create(:notebook_id => @notebook.id, :revision_id => @notebook.revisions.last.id, :revtype => "functional", :status => "queued", :comments => comments)
          count_created += 1
        elsif (Review.where(notebook_id: @notebook.id, revision_id: @notebook.revisions.last.id, revtype: "functional").count > 0)
          reviews_that_already_exist += 1
        end
      else
        if (Review.where(notebook_id: @notebook.id, revtype: "functional").count == 0)
          Review.create(:notebook_id => @notebook.id, :revtype => "functional", :status => "queued", :comments => comments)
          count_created += 1
        elsif (Review.where(notebook_id: @notebook.id, revtype: "functional").count > 0)
          reviews_that_already_exist += 1
        end
      end
    end
    if (reviews_that_already_exist > 0)
      if (reviews_that_already_exist == 1 && count_created == 0)
        flash[:error] = "Your review was not created successfully. Review already exists for this notebook version and review type already."
      elsif (reviews_that_already_exist == 2 && count_created == 0)
        flash[:error] = "None of your reviews were created successfully. Both of your proposed reviews already exist for this notebook version already."
      elsif (reviews_that_already_exist == 1 && count_created > 0)
        flash[:warning] = "One of your reviews have been created successfully, but the other was not created because a review of that type for this notebook version already exists."
      end
    else
      if (count_created == 1)
        flash[:success] = "Review has been created successfully."
      elsif (count_created > 1)
        flash[:success] = "Reviews have been created successfully."
      end
    end
    redirect_to(:back)
  end

  # POST /notebooks/:id/deprecate
  def deprecate
    @deprecated_notebook = DeprecatedNotebook.find_or_create_by(notebook_id: @notebook.id)
    @deprecated_notebook.deprecater_user_id = @user.id;
    if params[:freeze] == "no"
      @deprecated_notebook.disable_usage = FALSE
    else
      @deprecated_notebook.disable_usage = TRUE
    end
    if params[:alternatives] != "" && params[:alternatives] != nil
      @deprecated_notebook.alternate_notebook_ids = JSON.parse("#{[params[:alternatives]]}".gsub("\"","")).sort
    else
      @deprecated_notebook.alternate_notebook_ids = nil
    end
    @deprecated_notebook.reasoning = params[:comments]
    @deprecated_notebook.save
    clickstream('deprecated notebook', notebook: @notebook, tracking: notebook_path(@notebook))
    flash[:success] = "Successfully deprecated notebook."
    redirect_to(:back)
  end

  # POST /notebooks/:id/remove_deprecation_status
  def remove_deprecation_status
    DeprecatedNotebook.find_by(notebook_id: @notebook.id).destroy
    clickstream('un-deprecated notebook', notebook: @notebook, tracking: notebook_path(@notebook))
    flash[:success] = "Successfully removed deprecation status from notebook."
    redirect_to(:back)
  end

  # GET /notebooks/:id/reviews
  def reviews
  end


  #########################################################
  # Collection endpoints
  #########################################################

  # GET /notebooks
  def index
    @notebooks = query_notebooks
    if params[:q].blank?
      @tags = []
      @groups = []
    else
      words = params[:q].split.reject {|w| w.start_with? '-'}
      @tags = Tag.readable_by(@user, words)
      ids = Group.search_ids do
        fulltext(params[:q])
      end
      @groups = Group.readable_by(@user, ids).select {|group, _count| ids.include?(group.id)}
    end
    if params[:ajax].present? && params[:ajax] == 'true'
      render partial: 'notebooks'
    end
  end

  # GET /notebooks/stars
  def stars
    @notebooks = query_notebooks.where(id: @user.stars.pluck(:id))
    render 'index'
  end

  # GET /notebooks/recently_executed
  def recently_executed
    ids = @user
      .execution_histories
      .where('created_at > ?', 14.days.ago)
      .select(:notebook_id)
      .distinct
      .pluck(:notebook_id)
    # Re-query for notebooks in case permissions have changed
    @notebooks = query_notebooks.where(id: ids)
    render 'index'
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
    @tags = @user.tag_recommendations.take(10)
    @groups = @user.group_recommendations.take(10)
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

  # Save bits of Referer and internal 'ref' for clickstream
  def ref_tracking
    tracking = (request.headers['Referer'] || '').sub(request.base_url, '')[0...150]
    if params[:ref].present?
      tracking += ' ' unless tracking.empty?
      tracking += "(#{params[:ref]})"
    end
    tracking
  end

  # Figure out the owner object for new notebooks
  def determine_owner
    if params[:owner]&.start_with?('group:')
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

  # Save a new notebook to cache
  def save_new
    # The commit_id field is used by jupyter-docker to detect changes.  However,
    # the jupyter image only sees the result of the intial staging, so we use
    # the staging id instead of the real commit id from remote storage.  The
    # real commit id from git will go into clickstream log and revisions table.
    @notebook.commit_id = params[:staging_id]
    commit_message = "#{@user.user_name}: [new] #{@notebook.title}\n#{@notebook.description}"
    # Save to the db and to local cache
    @notebook.tags = @tags
    @notebook.content = @stage.content # saves to cache
    if @notebook.save
      @stage.destroy
      real_commit_id = Revision.notebook_create(@notebook, @user, commit_message)
      clickstream('agreed to terms')
      clickstream('created notebook', tracking: real_commit_id)
      true
    else
      # We checked validity before saving, so we don't expect to land here, but
      # if we do, we need to rollback the content storage.
      @notebook.remove_content
      false
    end
  end

  # Save an updated notebook to cache
  def save_update
    # See comments in #save_new for general strategy
    @notebook.commit_id = params[:staging_id]
    commit_message = "#{@user.user_name}: [edit] #{@notebook.title}"

    # Save to db and local cache
    @notebook.tags = @tags
    @notebook.content = @stage.content # saves to cache
    if @notebook.save
      @stage.destroy
      method = (@notebook.content == @old_content ? :notebook_metadata : :notebook_update)
      real_commit_id = Revision.send(method, @notebook, @user, commit_message)
      clickstream('agreed to terms')
      clickstream('edited notebook', tracking: real_commit_id)
      @notebook.notebook_summary.previous_health = @notebook.notebook_summary.health
      @notebook.notebook_summary.save
      @notebook.trendiness = 1.0
      true
    else
      # Rollback content storage
      @notebook.content = @old_content
      false
    end
  end

  def share_params
    old_shares = @notebook.shares.pluck(:user_name)
    new_shares =
      if params[:shares].is_a? Array
        params[:shares]
      else
        params[:shares].parse_csv.map(&:strip) rescue []
      end

    to_remove = (old_shares - new_shares).map do |share|
      User.find_by(user_name: share)
    end

    to_add = []
    non_member_emails = []
    errors = []
    (new_shares - old_shares).each do |share|
      user = User.find_by(user_name: share)
      if user
        to_add << user
      elsif GalleryLib.valid_email?(share)
        non_member_emails << share
      else
        # Everything must be valid username OR well-formed email address
        errors << share
      end
    end
    [to_remove, to_add, non_member_emails, errors]
  end
end
