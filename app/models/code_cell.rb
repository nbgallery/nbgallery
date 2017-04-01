# Code cell model
class CodeCell < ActiveRecord::Base
  belongs_to :notebook
  has_many :executions, dependent: :destroy

  validates :md5, :ssdeep, :notebook, :cell_number, presence: true

  # Return code associated with this cell
  # Note: this is not particularly efficient
  def source
    notebook.notebook.code_cells_source[cell_number]
  end

  # Executions from the last N days
  def latest_executions(days=nil)
    if days
      executions.where('created_at > ?', days.days.ago)
    else
      executions
    end
  end

  # Timestamp of latest execution
  def latest_execution
    executions.order(created_at: :desc).first&.created_at
  end

  # Number of executions in last N days
  def execution_count(days=nil)
    latest_executions(days).count
  end

  # Number of successful executions in last N days
  def pass_count(days=nil)
    latest_executions(days).where(success: true).count
  end

  # Number of failed executions in last N days
  def fail_count(days=nil)
    latest_executions(days).where(success: false).count
  end

  # Proportion of successful executions in last N days
  def pass_rate(days=nil)
    latest_executions(days).average('IF(success, 1, 0)')&.to_f
  end

  # Proprtion of failed executions in last N days
  def fail_rate(days=nil)
    latest_executions(days).average('IF(success, 0, 1)')&.to_f
  end

  # Average runtime over last N days
  def average_runtime(days=nil)
    latest_executions(days).average(:runtime)&.to_f
  end

  # Should we consider this cell a failure?
  def failed?(days=nil)
    rate = fail_rate(days)
    rate && rate > 0.25
  end

  # Summary of health info
  def health_status(days=nil)
    {
      execution_count: execution_count(days),
      pass_rate: pass_rate(days),
      average_runtime: average_runtime(days),
      failed: failed?(days)
    }
  end

  # Identical cells using md5 (no collision check)
  def identical_cells
    CodeCell.includes(:notebook).where(md5: md5).where.not(id: id)
  end

  # Similar cells using fuzzy hash
  def similar_cells
    prefix = ssdeep.split(':').first.to_i
    prefixes = [prefix, prefix * 2]
    prefixes.push(prefix / 2) unless prefix.odd?
    prefix_where = prefixes.map {|p| "ssdeep LIKE '#{p}:%'"}.join(' OR ')
    CodeCell
      .includes(:notebook)
      .where(prefix_where)
      .where.not(id: id)
      .map {|cell| [cell, Ssdeep.compare(ssdeep, cell.ssdeep)]}
      .reject {|_cell, score| score.zero?}
      .sort_by {|_cell, score| -score}
  end

  # Metrics url
  def url
    "/notebooks/#{notebook.uuid}/code_cells/#{cell_number}"
  end
end
