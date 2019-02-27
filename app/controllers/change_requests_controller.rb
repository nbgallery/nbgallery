# Controller for change requests
class ChangeRequestsController < ApplicationController
  before_action :set_change_request, except: %i[index all create]
  before_action :verify_login
  before_action :verify_accepted_terms, only: %i[create accept]
  before_action :verify_view_change_request, except: %i[index all create]
  before_action :verify_edit_or_admin, only: %i[accept decline]
  before_action :verify_requestor_or_admin, only: [:cancel]
  before_action :verify_admin, only: %i[all destroy]
  before_action :verify_pending_status, only: %i[accept decline cancel]
  before_action :set_stage, only: [:create]

  # GET /change_requests
  def index
    # This is limited to those owned/requested by @user

    sorter = proc do |a, b|
      if a.status == 'pending' and b.status != 'pending'
        -1
      elsif a.status != 'pending' and b.status == 'pending'
        1
      elsif a.status == b.status
        b.updated_at <=> a.updated_at
      else
        a.status <=> b.status
      end
    end

    @change_requests_requested = @user.change_requests.sort(&sorter)
    @change_requests_owned = @user.change_requests_owned.sort(&sorter)
    @change_requests = @change_requests_requested + @change_requests_owned
  end

  # GET /change_requests/all
  def all
    # This is for admins to view all requests
    @change_requests = ChangeRequest.all
  end

  # GET /change_requests/:reqid
  def show
  end

  # GET /change_requests/:reqid/diff
  def diff
    render layout: false
  end

  # GET /change_requests/:reqid/compare
  def compare
    render layout: false
  end

  # GET /change_requests/:reqid/diff_inline
  def diff_inline
    render layout: false
  end

  # GET /change_requests/:reqid/download
  def download
    send_file(
      @change_request.filename,
      filename: "#{@notebook.title} -- Change Request.ipynb"
    )
  end

  # POST /change_requests
  def create
    # Get the notebook the request is targeted for
    @notebook = Notebook.find_by!(uuid: params[:notebook_id])
    if @stage.content == @notebook.content
      raise ChangeRequest::BadUpload, 'proposed content is the same as the original'
    end

    # Validate staged content
    raise ChangeRequest::BadUpload.new('bad content', @jn.errors) if @jn.invalid?(@notebook, @user, params)

    # Create the change request object
    @change_request = ChangeRequest.new(
      reqid: SecureRandom.uuid,
      requestor: @user,
      notebook: @notebook,
      status: 'pending',
      requestor_comment: params[:comment]
    )
    # Set fields defined in extensions
    ChangeRequest.extension_attributes.each do |attr|
      @change_request.send("#{attr}=".to_sym, params[attr]) if params[attr]
    end

    # Check validity and save content
    raise ChangeRequest::BadUpload.new('invalid parameters', @change_request.errors) if @change_request.invalid?
    @change_request.proposed_content = @stage.content # saves to cache

    # Save it
    if @change_request.save
      @stage.destroy
      clickstream('agreed to terms')
      clickstream('submitted change request', tracking: @change_request.reqid)
      ChangeRequestMailer.create(@change_request, request.base_url).deliver_later
      render json: { reqid: @change_request.reqid, url: url_for(@change_request) }, status: :created
    else
      @change_request.remove_content
      render json: @change_request.errors, status: :unprocessable_entity
    end
  end

  # DELETE /change_requests/:reqid
  def destroy
    # Normally requests are only destroyed by age-off
    @change_request.destroy
    head :no_content
  end

  # PATCH /change_requests/:reqid/accept
  def accept
    # Content must be validated again in the context of the owner
    jn = @change_request.proposed_notebook
    raise Noteboook::BadUpload.new('bad content', jn.errors) if jn.invalid?(@notebook, @user, params)

    # Update notebook object
    @notebook.lang, @notebook.lang_version = jn.language
    @notebook.updater = @change_request.requestor
    Notebook.extension_attributes.each do |attr|
      next unless @change_request.respond_to?(attr)
      value = @change_request.send(attr)
      @notebook.send("#{attr}=".to_sym, value) if value.present?
    end
    raise Notebook::BadUpload.new('invalid parameters', @notebook.errors) if @notebook.invalid?

    # Save the content
    old_content = @notebook.content
    new_content = @change_request.proposed_content
    commit_message =
      "#{@user.user_name}: [edit] #{@notebook.title}\n" \
      "Accepted change request from #{@change_request.requestor.user_name}"

    # Save the notebook - note the requestor gets "edit" credit
    @notebook.content = new_content # saves to cache
    if @notebook.save
      @change_request.status = 'accepted'
      @change_request.owner_comment = params[:comment]
      @change_request.save
      method = (new_content == old_content ? :notebook_metadata : :notebook_update)
      real_commit_id = Revision.send(method, @notebook, @change_request.requestor, commit_message)
      clickstream('agreed to terms')
      clickstream('accepted change request', tracking: @change_request.reqid)
      clickstream('edited notebook', user: @change_request.requestor, tracking: real_commit_id)
      ChangeRequestMailer.accept(@change_request, @user, request.base_url).deliver_later
      render json: { message: 'change request accepted' }
    else
      # Rollback the content storage
      @notebook.content = old_content
      render json: @notebook.errors, status: :unprocessable_entity
    end
  end

  # PATCH /change_requests/:reqid/decline
  def decline
    @change_request.status = 'declined'
    @change_request.owner_comment = params[:comment]
    @change_request.save!
    clickstream('declined change request', tracking: @change_request.reqid)
    ChangeRequestMailer.decline(@change_request, @user, request.base_url).deliver_later
    render json: { message: 'change request declined' }
  end

  # PATCH /change_requests/:reqid/cancel
  def cancel
    @change_request.status = 'canceled'
    @change_request.save!
    clickstream('canceled change request', tracking: @change_request.reqid)
    ChangeRequestMailer.cancel(@change_request, request.base_url).deliver_later
    render json: { message: 'change request canceled' }
  end

  private

  # Look up change request by id or reqid
  def set_change_request
    @change_request =
      if GalleryLib.uuid?(params[:id])
        ChangeRequest.find_by!(reqid: params[:id])
      else
        ChangeRequest.find(params[:id])
      end
    @notebook = @change_request.notebook
  end

  # Only requestor and owner of the notebook can view
  def verify_view_change_request
    raise User::Forbidden, 'you are not allowed to view this request' unless
      @change_request.requestor == @user || @user.can_edit?(@notebook, true)
  end

  # Only requestor can cancel
  def verify_requestor_or_admin
    raise User::Forbidden, 'you are not allowed to cancel this request' unless
      @change_request.requestor == @user || @user.admin?
  end

  # Must be in pending status to do stuff
  def verify_pending_status
    raise ChangeRequest::NotPending, 'change request is not in pending status' unless
      @change_request.status == 'pending'
  end
end
