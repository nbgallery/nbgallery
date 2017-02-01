# Controller for execution logs
class ExecutionsController < ApplicationController
  before_action :verify_login

  # POST /executions
  def create
    unless GalleryConfig.instrumentation.enabled
      render json: { message: 'instrumentation disabled' }, status: :forbidden
      return
    end

    nb = Notebook.find_by!(uuid: params[:uuid])
    cell = nb.code_cells.find_by!(md5: params[:md5])
    @execution = Execution.new(
      user: @user,
      code_cell: cell,
      success: params[:success].to_bool,
      runtime: params[:runtime].to_f
    )
    @execution.save!
    render json: { message: 'execution log accepted' }, status: :ok
  end
end
