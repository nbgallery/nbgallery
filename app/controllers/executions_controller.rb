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
    notebook_id = Notebook.where(uuid: params[:uuid]).limit(1).map(&:id).first
    raise ActiveRecord::RecordNotFound, "Couldn't find Notebook" unless notebook_id
    cell_id, cell_number = CodeCell
      .where(notebook_id: notebook_id, md5: params[:md5])
      .limit(1)
      .map{ |cell| [cell.id, cell.cell_number]}
      .first
    log_execution_history(@user, notebook_id, cell_id)

    # If known cell, log execution record
    if cell_id
      success = params[:success].to_bool
      Execution.create!(
        user: @user,
        code_cell_id: cell_id,
        success: success,
        runtime: params[:runtime].to_f
      )

      # Not perfect, but try to log a click for each execution of the whole notebook
      origin = (ENV['HTTP_ORIGIN'] || request.headers['HTTP_ORIGIN'] || '').sub(%r{https?://}, '')
      clickstream('executed notebook', notebook_id: notebook_id, tracking: origin) if success && cell_number&.zero?
    end

    render json: { message: 'execution log accepted' }, status: :ok
  end

  private

  def log_execution_history(user, notebook_id, cell_id)
    cell_field = cell_id ? :known_cell : :unknown_cell
    eh = ExecutionHistory.new(
      user: user,
      notebook_id: notebook_id,
      day: Time.current.to_date
    )
    eh[cell_field] = true
    ExecutionHistory.import([eh], on_duplicate_key_update: [cell_field])
  end
end
