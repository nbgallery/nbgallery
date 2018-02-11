# Controller for execution logs
class ExecutionsController < ApplicationController
  before_action :verify_login

  # POST /executions
  def create
    unless GalleryConfig.instrumentation.enabled
      render json: { message: 'instrumentation disabled' }, status: :forbidden
      return
    end

    # Log fact of notebook execution to history table
    @notebook = Notebook.find_by!(uuid: params[:uuid])
    cell = @notebook.code_cells.find_by(md5: params[:md5])
    log_execution_history(@user, @notebook, cell)

    # If known cell, log execution record
    if cell
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
    end

    render json: { message: 'execution log accepted' }, status: :ok
  end

  private

  def log_execution_history(user, notebook, cell)
    history = ExecutionHistory
      .where(user: user)
      .where(notebook: notebook)
      .where('created_at LIKE ?', "#{Time.current.to_date}%")
      .first
    history ||= ExecutionHistory.new(user: user, notebook: notebook)
    if cell
      history.known_cell = true
    else
      history.unknown_cell = true
    end
    history.save
  end
end
