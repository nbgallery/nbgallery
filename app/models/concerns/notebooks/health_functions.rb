# Notebook model functionality
module Notebooks
  # Instrumentation and health functions for Notebooks
  module HealthFunctions
    extend ActiveSupport::Concern

    # Class-level health functions
    module ClassMethods
      # Most recently executed notebooks
      def recently_executed
        joins(:executions)
          .select('notebooks.*, MAX(executions.updated_at) AS last_exec')
          .group('notebooks.id')
          .order('last_exec DESC')
      end

      # Most recently executed with failures
      def recently_failed
        joins(:executions)
          .where('executions.success = 0')
          .select('notebooks.*, MAX(executions.updated_at) AS last_failure')
          .group('notebooks.id')
          .order('last_failure DESC')
      end

      def health_symbol(score)
        return :undetermined unless score
        return :healthy if score >= 0.625
        return :unhealthy if score <= 0.375
        :undetermined
      end
    end

    # Is notebook healthy? (note: uses cached value in summary)
    def healthy?
      Notebook.health_symbol(notebook_summary.health) == :healthy
    end

    # Is notebook unhealthy? (note: uses cached value in summary)
    def unhealthy?
      Notebook.health_symbol(notebook_summary.health) == :unhealthy
    end

    def runtime_by_cell(days=30)
      executions
        .joins(:code_cell)
        .where('executions.updated_at > ?', days.days.ago)
        .select('AVG(runtime) AS runtime, code_cells.cell_number')
        .group('cell_number')
        .map {|e| [e.cell_number, e.runtime]}
        .to_h
    end

    # Executions from the last N days
    def latest_executions(days=30)
      if days
        executions.where('executions.updated_at > ?', days.days.ago)
      else
        executions
      end
    end

    # Execution history (users per day)
    def execution_history(days=30)
      notebook_dailies
        .where('day >= ?', days.days.ago.to_date)
        .map{ |d| [d.day, d.unique_executors] }
        .to_h
    end

    # Number of users over last N days
    def unique_users(days=30)
      latest_executions(days).select(:user_id).distinct.count
    end

    # Health score based on execution logs
    # Returns something in the range [0, 1]
    def compute_health(days=30)
      num_cells = code_cells.count
      num_executions = latest_executions(days).count
      num_users = unique_users(days)
      return nil if num_executions.zero? || num_cells.zero?

      scale = Execution.health_scale(num_users, num_executions.to_f / num_cells)
      scaled_pass_rate = scale * pass_rate(days)
      scaled_depth = scale * notebook_execution_depth(days)

      (scaled_pass_rate + scaled_depth) / 2.0
    end

    # Overall execution pass rate
    def pass_rate(days=30)
      num_executions = latest_executions(days).count
      return nil if num_executions.zero?
      num_success = latest_executions(days).where(success: true).count
      num_success.to_f / num_executions
    end

    def execution_depths(days=30)
      num_cells = code_cells.count
      return {} if num_cells.zero?

      # Group by (user,day) to approximate a "session" of running the notebook
      sessions = executions
        .joins(:code_cell)
        .where('executions.updated_at > ?', days.days.ago)
        .select([
          'user_id',
          'DATE(executions.updated_at) AS day',
          'success',
          'MIN(code_cells.cell_number) AS failure',
          'MAX(code_cells.cell_number) + 1 AS depth'
        ].join(', '))
        .group('user_id, day, success')
        .group_by {|result| [result.user_id, result.day]}

      # Add up exec depth and first failure from all sessions
      depths = 0.0
      failures = 0.0
      sessions.each_value do |values|
        # Convert to {true => max success, false => min failure}
        hash = values.map {|v| [v.success, v.success ? v.depth : v.failure]}.to_h

        # Execution depth = highest-numbered cell successfully executed,
        # divided by number of cells.  Default to 0 if no successess.
        depths += (hash[true] || 0).to_f / num_cells

        # First failure = lowest-numbered cell with failure, divided by
        # number of cells.  Default to 1 if no failures.
        failures += (hash[false] || num_cells).to_f / num_cells
      end

      # Return average across all sessions
      {
        notebook_execution_depth: depths.to_f / sessions.count,
        first_failure_depth: failures.to_f / sessions.count
      }
    end

    # On average, where do users encounter their first failure?
    def first_failure_depth(days=30)
      execution_depths(days)[:first_failure_depth]
    end

    # On average, how far into the notebooks do users get?
    def notebook_execution_depth(days=30)
      execution_depths(days)[:notebook_execution_depth]
    end

    # Number of unhealthy cells
    def unhealthy_cells(days=30)
      code_cells.select {|cell| cell.health_status(days)[:status] == :unhealthy}.count
    end

    # Cell counts etc
    def cell_metrics(days=30)
      status = {
        total_cells: 0,
        unhealthy_cells: 0,
        healthy_cells: 0,
        undetermined_cells: 0
      }

      first_bad_cell = nil
      last_good_cell = 0
      code_cells.each do |cell|
        metrics = cell.health_status(days)
        status[:total_cells] += 1
        if metrics[:status] == :healthy
          status[:healthy_cells] += 1
          last_good_cell = cell.cell_number + 1
        elsif metrics[:status] == :unhealthy
          status[:unhealthy_cells] += 1
          first_bad_cell ||= cell.cell_number
        else
          status[:undetermined_cells] += 1
        end
      end

      # First bad / last good, as a fraction of total
      if status[:total_cells].positive?
        status[:first_bad_cell] =
          first_bad_cell ? (first_bad_cell.to_f / status[:total_cells]) : 1.0
        status[:last_good_cell] = last_good_cell.to_f / status[:total_cells]
      end

      status
    end

    # More detailed health status
    def health_status(days=30)
      num_cells = code_cells.count
      if num_cells.zero?
        return {
          status: :undetermined,
          description: 'Undetermined health: has no code cells',
          total_cells: 0
        }
      end
      num_executions = latest_executions(days).count
      if num_executions.zero?
        return adjust_health_score(
          status: :undetermined,
          description: "Undetermined health: has no executions in last #{days} days",
          total_cells: num_cells,
          executions: 0
        )
      end

      # Health metrics
      status = cell_metrics(days)
      status[:executions] = num_executions
      status[:users] = unique_users(days)
      scale = Execution.health_scale(status[:users], num_executions.to_f / num_cells)
      status[:usage_factor] = scale
      status[:overall_success_rate] = pass_rate(days)
      status[:first_failure_depth] = first_failure_depth(days)
      status[:notebook_execution_depth] = notebook_execution_depth(days)
      status[:good_cell_ratio] = status[:healthy_cells].to_f / num_cells
      status[:bad_cell_ratio] = status[:unhealthy_cells].to_f / num_cells
      status[:score] = compute_health(days)

      # Healthy or not
      status[:status] = Notebook.health_symbol(status[:score])
      users = "#{status[:users]} #{'user'.pluralize(status[:users])}"
      score = "#{(status[:score] * 100).truncate}%"
      status_str = status[:status].to_s.capitalize
      status[:description] =
        "#{status_str}: #{score} health score (#{users}) in last #{days} days"

      adjust_health_score(status)
    end

    # Adjust health score using pre-update value
    def adjust_health_score(status)
      # For updated notebooks, we factor in the previous score if:
      #   * current health is undetermined
      #   * previous health was NOT undetermined
      #   * update was less than a week ago
      status[:adjusted_score] = status[:score]
      return status unless status[:status] == :undetermined
      previous = notebook_summary.previous_health
      previous_symbol = Notebook.health_symbol(previous)
      return status unless previous_symbol != :undetermined
      update_age = Time.current - content_updated_at
      return status unless update_age < 7.days

      # Weighted average of previous and current scores.
      # If no current execution data, previously healthy notebooks degrade
      # to 0.5 and unhealthy ones degrade to 0.
      default_score = previous_symbol == :healthy ? 0.5 : 0.0
      scale = update_age.to_f / 7.days
      status[:adjusted_score] = scale * (status[:score] || default_score) + (1.0 - scale) * previous
      previous_str = previous_symbol.to_s
      status[:description] = "Undetermined health: but previously #{previous_str}"
      status
    end

    # Cell-level health for all cells
    # Equivalent of calling health_status on each cell.
    def cell_health_status(days=30)
      metrics = Execution.raw_cell_metrics(days: days, notebook: id)
      code_cells.map {|cell| [cell.id, CodeCell.groom_metrics(metrics[cell.id], days)]}.to_h
    end
  end
end
