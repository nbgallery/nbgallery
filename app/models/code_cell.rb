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
  def latest_executions(days=30)
    if days
      executions.where('updated_at > ?', days.days.ago)
    else
      executions
    end
  end

  # Timestamp of latest execution
  def latest_execution
    executions.order(updated_at: :desc).first&.updated_at
  end

  # Number of executions in last N days
  def execution_count(days=30)
    latest_executions(days).count
  end

  # Number of successful executions in last N days
  def pass_count(days=30)
    latest_executions(days).where(success: true).count
  end

  # Number of failed executions in last N days
  def fail_count(days=30)
    latest_executions(days).where(success: false).count
  end

  # Proportion of successful executions in last N days
  def pass_rate(days=30)
    latest_executions(days).average('IF(success, 1, 0)')&.to_f
  end

  # Proprtion of failed executions in last N days
  def fail_rate(days=30)
    latest_executions(days).average('IF(success, 0, 1)')&.to_f
  end

  # Average runtime over last N days
  def average_runtime(days=30)
    latest_executions(days).average(:runtime)&.to_f
  end

  # Number of unique users over last N days
  def unique_users(days=30)
    latest_executions(days).select(:user_id).distinct.count
  end

  # Number of users with failures over last N days
  def unique_users_with_failures(days=30)
    latest_executions(days).where(success: false).select(:user_id).distinct.count
  end

  # Groom metrics helper
  def self.groom_metrics(metrics, days)
    if metrics.blank?
      metrics = {
        status: :undetermined,
        description: "No executions in last #{days} days"
      }
    else
      scale = Execution.health_scale(metrics[:users], metrics[:executions])
      metrics[:usage_factor] = scale
      scaled_pass_rate = metrics[:pass_rate] * scale
      metrics[:status] = scaled_pass_rate >= 0.75 ? :healthy : :unhealthy
      users = "#{metrics[:users]} #{'user'.pluralize(metrics[:users])}"
      metrics[:description] =
        "#{(metrics[:pass_rate] * 100).truncate}% pass rate (#{users}) in last #{days} days"
    end
    metrics
  end

  # Summary of health info
  def health_status(days=30)
    metrics = Execution.raw_cell_metrics(days: days, cell: id)
    CodeCell.groom_metrics(metrics[id], days)
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

  def to_param
    (cell_number + 1).to_s
  end

  # Metrics url
  def url
    "/notebooks/#{notebook.uuid}/code_cells/#{cell_number}"
  end

  # Graph with x = fail rate, y = cells with fail rate >= x
  def self.cumulative_fail_rates
    fail_rates = {}
    (0..100).each {|i| fail_rates[i] = 0}
    cell_metrics = Execution.raw_cell_metrics
    cell_metrics.each_value do |info|
      fail_rates[(info[:fail_rate] * 100).floor] += 1
    end
    cumulative = {}
    total = 0
    fail_rates.to_a.reverse_each do |rate, count|
      total += count
      cumulative[rate.to_f / 100.0] = total / cell_metrics.count.to_f
    end
    cumulative.to_a.sort_by(&:first)
  end
end
