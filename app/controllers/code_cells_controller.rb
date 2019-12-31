# Code cells controller
class CodeCellsController < ApplicationController
  before_action :set_notebook
  before_action :verify_read_or_admin
  before_action :set_code_cell

  # GET /notebooks/:notebook_id/code_cells/:cell_number
  def show
    # Renderer is expecting ipynb-style json
    @source = @code_cell.source
    @cell_json = {
      'cell_type' => 'code',
      'source' => @source,
      'outputs' => []
    }

    # Health stuff
    @execs = exec_helper(nil, false)
    @execs_last30 = exec_helper(nil, true)
    @execs_pass = exec_helper(true, false)
    @execs_pass_last30 = exec_helper(true, true)
    @execs_fail = exec_helper(false, false)
    @execs_fail_last30 = exec_helper(false, true)
    @executions_by_day = execution_success_chart(@code_cell, 'DATE(executions.updated_at)', :day)

    # Similar cells
    @similar = @code_cell
      .similar_cells
      .select {|cell, _score| @user.can_read?(cell.notebook)}
      .take(20)
    @identical = @code_cell
      .identical_cells
      .select {|cell| @user.can_read?(cell.notebook)}
      .shuffle
      .take(20)
  end

  protected

  # Get the notebook
  def set_notebook
    notebook_from_partial_uuid(params[:notebook_id])
  end

  # Get the code cell
  def set_code_cell
    @code_cell = CodeCell.find_by!(notebook: @notebook, cell_number: (params[:id].to_i - 1).to_s)
  end

  # Execution counts
  def exec_helper(success, last30)
    relation = @code_cell.executions
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('executions.updated_at > ?', 30.days.ago) if last30
    relation.count
  end
end
