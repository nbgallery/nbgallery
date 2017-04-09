# Code cell execution model
class Execution < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_cell
  has_one :notebook, through: :code_cell

  validates :success, not_nil: true
  validates :runtime, :user, :code_cell, presence: true

  class << self
    # Raw metrics on all executed cells
    def raw_cell_metrics(days=30)
      results = where('updated_at > ?', days.days.ago)
        .select([
          'code_cell_id',
          'COUNT(*) AS count',
          'AVG(IF(success, 0, 1)) AS fail_rate',
          'COUNT(DISTINCT(user_id)) AS users',
          'MAX(updated_at) AS last_execution',
          'DATEDIFF(now(), MAX(updated_at)) AS last_execution_age'
        ].join(', '))
        .group(:code_cell_id)

      results = results.map do |result|
        metrics = {
          executions: result.count,
          fail_rate: result.fail_rate.to_f,
          pass_rate: 1.0 - result.fail_rate.to_f,
          users: result.users,
          last_execution: result.last_execution,
          last_execution_age: result.last_execution_age
        }
        [result.code_cell_id, metrics]
      end

      results.to_h
    end
  end
end
