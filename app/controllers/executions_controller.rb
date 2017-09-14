# Controller for execution logs
class ExecutionsController < ApplicationController
  before_action :verify_login

  # POST /executions
  def create
    unless GalleryConfig.instrumentation.enabled
      render json: { message: 'instrumentation disabled' }, status: :forbidden
      return
    end

    @notebook = Notebook.find_by!(uuid: params[:uuid])
    cell = @notebook.code_cells.find_by!(md5: params[:md5])
    success = params[:success].to_bool
    @execution = Execution.new(
      user: @user,
      code_cell: cell,
      success: success,
      runtime: params[:runtime].to_f
    )
    @execution.save!
    # Not perfect, but try to log a click for each execution of the whole notebook
    origin = ENV['HTTP_ORIGIN'] || request.headers['HTTP_ORIGIN']
    origin.sub!(%r{https?://}, '')
    clickstream('executed notebook', tracking: origin) if success && cell.cell_number.zero?
    render json: { message: 'execution log accepted' }, status: :ok
  end
end
