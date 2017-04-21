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

    # Language by day summary
    def languages_by_day(days=30)
      joins(:code_cell, :notebook)
        .where('executions.updated_at > ?', days.days.ago)
        .select([
          'count(distinct(notebooks.id)) AS count',
          'notebooks.lang AS lang',
          'DATE(executions.updated_at) AS day'
        ].join(','))
        .group('lang, day')
        .order('day, lang')
        .group_by(&:lang)
        .map {|lang, entries| [lang, entries.map {|e| [e.day, e.count]}.to_h]}
        .to_h
    end

    # Users by day summary
    def users_by_day(days=30)
      joins(:code_cell)
        .where('executions.updated_at > ?', days.days.ago)
        .select('COUNT(DISTINCT(user_id)) AS count, DATE(executions.updated_at) AS day')
        .group('day')
        .map {|e| [e.day, e.count]}
        .sort_by {|day, _count| day}
        .to_h
    end
  end
end
