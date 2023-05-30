# Revision controller
class RevisionsController < ApplicationController
  before_action :set_notebook
  before_action :verify_read_or_admin
  before_action :set_revisions
  before_action :set_revision, except: %i[index latest_diff]
  before_action :set_other_revision, only: %i[diff]

  # GET /notebooks/:notebook_id/revisions
  def index
  end

  # GET /notebooks/:notebook_id/revisions/:commit_id
  def show
  end

  # GET /notebooks/:notebook_id/revisions/:commit_id/download
  def download
    jn = @revision.content
    # Clear out any gallery meta, since may not be the current notebook
    jn['metadata']['gallery'] = {} if jn.dig('metadata', 'gallery')
    title = "#{@notebook.title} - Rev #{@revision.commit_id.first(8)}"
    send_data(jn.to_json, filename: "#{title}.ipynb")
  end

  # GET /notebooks/:notebook_id/revisions/:commit_id/diff?revision=xyz
  def diff
    before = @revision.content.text_for_diff
    after = @other_revision.content.text_for_diff
    @diff = GalleryLib::Diff.split(before, after)
  end

  # GET /notebooks/:notebook_id/revisions/:commit_id/metadata
  def metadata
    meta = {}
    meta[:git_commit_id] = @revision.commit_id
    meta[:title] = "#{@notebook.title} - Rev #{@revision.commit_id.first(8)}"
    render json: meta
  end

  # GET /notebooks/:notebook_id/revisions/latest_diff
  def latest_diff
    revs = @revisions.reject {|r| r.revtype == 'metadata'}
    if revs.count >= 2
      # user-viewable revisions list is most-recent first
      @revision = revs[1]
      @other_revision = revs[0]
      before = @revision.content.text_for_diff
      after = @other_revision.content.text_for_diff
      @diff = GalleryLib::Diff.split(before, after)
      render 'diff'
    else
      # TODO
      render text:
        'Sorry, either there is only the latest revision ' \
        'or you are not allowed to see the previous one.'
    end
  end

  # PATCH /notebooks/:notebook_id/revisions/:commit_id/edit_friendly_label
  def edit_friendly_label
    errors = ""
    notebook = Notebook.find(@revision.notebook_id)
    friendly_label = params[:friendly_label].strip
    label_check_bad = verify_revision_label(friendly_label, notebook, params[:old_label])
    if label_check_bad
      errors += label_check_bad
    end
    if errors.length <= 0
      if friendly_label.strip != ""
        @revision.friendly_label = friendly_label
      else
        @revision.friendly_label = nil
      end
      @revision.save!
      # Refresh page if user resets the version, else inline alert it was updated successfully
      if @revision.friendly_label == nil
        flash[:success] = 'Friendly label for revision has been reset successfully.'
        if request.xhr?
          render :js => %(window.location.href='#{notebook_revisions_path(@notebook.id)}')
        else
          redirect_back(fallback_location: root_path)
        end
      else
        render json: { message: 'Friendly label for revision has been updated successfully.' }, status: :ok
      end
    else
      render json: { message: errors }, status: :unprocessable_entity
    end
  end

  # PATCH /notebooks/:notebook_id/revisions/:commit_id/edit_summary
  def edit_summary
    errors = ""
    revision_summary = params[:summary].strip
    if revision_summary.length > 250
      errors += "Revision summary was too long. Summary can only be a maximum of 250 characters and you submitted one that was #{revision_summary.length} characters. "
    end
    if errors.length <= 0
      @revision.commit_message = revision_summary
      @revision.save!
      flash[:success] = "Revision summary has been updated successfully."
      if request.xhr?
        render :js => %(window.location.href='#{notebook_revisions_path(@notebook.id)}')
      else
        redirect_back(fallback_location: root_path)
      end
    else
      flash[:error] = "Revision summary edit failed. " + errors
      if request.xhr?
        render :js => %(window.location.href='#{notebook_revisions_path(@notebook.id)}')
      else
        redirect_back(fallback_location: root_path)
      end
    end
  end

  protected

  # Get the notebook
  def set_notebook
    notebook_from_partial_uuid(params[:notebook_id])
  end

  # Get revisions readable by user
  def set_revisions
    @revisions = @notebook.revision_list(@user)
  end

  # Helper to find a revision and check permissions
  def find_revision(commit_id)
    # Throw 404 if it doesn't even exist
    @notebook.revisions.find_by!(commit_id: commit_id)
    # Throw forbidden if not in user's allowed list
    revision = @revisions.select {|rev| rev.commit_id == commit_id}.last
    raise User::Forbidden, 'You are not allowed to view this revision.' unless revision
    revision
  end

  # Get the revision object
  def set_revision
    @revision = find_revision(params[:id])
  end

  # Get the other revision for diff
  def set_other_revision
    @other_revision = params[:revision] ? find_revision(params[:revision]) : @revisions.first
  end
end
