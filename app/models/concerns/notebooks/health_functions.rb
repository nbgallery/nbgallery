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
    end

    # Health score based on execution logs
    def compute_health
      num_executions = executions.count
      num_success = executions.where(success: true).count
      num_success.to_f / num_executions if num_executions.positive?
    end

    # How far into the notebook do users get?
    def execution_depth(days=30)
      num_cells = code_cells.count
      return 0.0 if num_cells.zero?

      # Group by (user,day) to approximate a "session" of running the notebook
      depths = executions
        .joins(:code_cell)
        .where(success: true)
        .where('executions.updated_at > ?', days.days.ago)
        .select('user_id, DATE(executions.updated_at) AS day, MAX(code_cells.cell_number) + 1 AS depth')
        .group('user_id, day')
        .map(&:depth)

      # Average across all sessions then return as fraction of total cells
      return 0.0 if depths.blank?
      average_depth = depths.reduce(&:+).to_f / depths.count
      average_depth / num_cells
    end

    # Number of failed cells
    def failed_cells(days=30)
      code_cells.select {|cell| cell.failed?(days)}.count
    end

    # More detailed health status
    def health_status(days=30)
      status = {
        failed_cells: failed_cells(days),
        total_cells: code_cells.count,
        score: health
      }
      status[:status] =
        if status[:score].nil?
          :unknown
        elsif status[:score] > 0.75 && status[:failed_cells] < 2
          :healthy
        else
          :unhealthy
        end
      status
    end
  end
end
