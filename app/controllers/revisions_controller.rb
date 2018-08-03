# Revision controller
class RevisionsController < ApplicationController
  before_action :set_notebook
  before_action :verify_read_or_admin
  before_action :set_revisions
  before_action :set_revision, only: [:show]

  # GET /notebooks/:notebook_id/revisions
  def index
  end

  # GET /notebooks/:notebook_id/revisions/:commit_id
  def show
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

  # Get specific revision
  def set_revision
    # Throw 404 if it doesn't even exist
    @notebook.revisions.find_by!(commit_id: params[:id])
    # Throw forbidden if not in user's allowed list
    @revision = @revisions.select {|rev| rev.commit_id == params[:id]}.first
    raise User::Forbidden, 'you are not allowed to view this revision' unless @revision
  end
end
