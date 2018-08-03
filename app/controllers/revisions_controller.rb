# Revision controller
class RevisionsController < ApplicationController
  before_action :set_notebook
  before_action :verify_read_or_admin
  before_action :set_revisions
  before_action :set_revision, except: %i[index]
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
    raise User::Forbidden, 'you are not allowed to view this revision' unless revision
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
