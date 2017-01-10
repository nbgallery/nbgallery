# Controller for notebook staging
class StagesController < ApplicationController
  before_action :verify_login
  before_action :verify_admin, except: [:create, :preprocess]
  before_action :verify_accepted_terms, only: [:create]
  before_action :set_stage, only: [:show, :destroy, :preprocess]

  # GET /stages
  def index
    @stages = Stage.all
  end

  # GET /stages/:uuid
  def show
  end

  # POST /stages
  def create
    # Parse & validate the submitted content
    content, filename = uploaded_file
    jn = JupyterNotebook.new(content)

    if params[:id]
      # Staging an edit or a change request to existing notebook.
      # Must at least have read permissions on the notebook.
      nb = Notebook.find_by_uuid!(params[:id])
      raise User::Forbidden, 'you are not allowed to view this notebook' unless
        @user.can_read?(nb, true)
      trusted = nb.trusted?
      can_edit = @user.can_edit?(nb, true)
    else
      # New notebook - never trusted
      trusted = false
      can_edit = true
    end

    # Prep content for storage
    jn.strip_output! unless trusted
    jn.strip_gallery_meta!

    # Store on disk and db
    staging_id = SecureRandom.uuid
    @stage = Stage.new(uuid: staging_id, user: @user)

    if @stage.save
      @stage.content = jn.to_json
      info = {
        commit: @stage.uuid,
        staging_id: @stage.uuid,
        filename: filename
      }
      if can_edit
        # New notebook or edit.
        # Staging id will become the notebook id for new ones.
        info[:link] = params[:id] || staging_id
      else
        # Existing notebook but not editable => change request
        info[:clone] = params[:id]
      end
      render json: info, status: :created
    else
      render json: @stage.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stages/:uuid
  def destroy
    @stage.destroy
    respond_to do |format|
      format.html {redirect_to stages_url, notice: 'Stage was successfully destroyed.'}
      format.json {head :no_content}
    end
  end

  # GET /stages/:uuid/preprocess
  def preprocess
    render json: @stage.notebook.preprocess(@user), status: :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_stage
    @stage = Stage.find_by!(uuid: params[:id])
  end

  # Get uploaded content depending on method
  def uploaded_file
    if params[:file].nil?
      [request.body.read, nil]
    else
      unless params[:file].respond_to?(:tempfile) && params[:file].respond_to?(:original_filename)
        raise JupyterNotebook::BadFormat, 'expected a file object'
      end
      unless params[:file].original_filename.end_with?('.ipynb')
        raise JupyterNotebook::BadFormat, 'file extension must be .ipynb'
      end
      [params[:file].tempfile.read, File.basename(params[:file].original_filename)]
    end
  end
end
