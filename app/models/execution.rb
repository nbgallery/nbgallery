# Code cell execution model
class Execution < ActiveRecord::Base
  belongs_to :user
  belongs_to :code_cell
  has_one :notebook, through: :code_cell

  validates :success, not_nil: true
  validates :runtime, :user, :code_cell, presence: true

  class << self
    # Raw metrics on all executed cells
    def raw_cell_metrics(options={})
      days = options[:days] || 30
      relation = where('executions.updated_at > ?', days.days.ago)
      if options[:cell]
        relation = relation.where(code_cell_id: options[:cell])
      elsif options[:notebook]
        relation = relation
          .joins(:code_cell)
          .where('notebook_id = ?', options[:notebook])
      end

      results = relation
        .select([
          'code_cell_id',
          'COUNT(*) AS count',
          'AVG(IF(success, 0, 1)) AS fail_rate',
          'COUNT(DISTINCT(user_id)) AS users',
          'MAX(executions.updated_at) AS last_execution',
          'DATEDIFF(now(), MAX(executions.updated_at)) AS last_execution_age'
        ].join(', '))
        .group(:code_cell_id)

      results = results.map do |result|
        metrics = {
          executions: result.count,
          fail_rate: result.fail_rate.to_f,
          pass_rate: 1.0 - result.fail_rate.to_f,
          users: result.users,
          failure_users: 0,
          last_execution: result.last_execution,
          last_execution_age: result.last_execution_age,
          last_failure: nil,
          last_failure_age: nil
        }
        [result.code_cell_id, metrics]
      end
      results = results.to_h

      failed = relation
        .where(success: false)
        .select([
          'code_cell_id',
          'COUNT(DISTINCT(user_id)) AS failure_users',
          'MAX(executions.updated_at) AS last_failure',
          'DATEDIFF(now(), MAX(executions.updated_at)) AS last_failure_age'
        ].join(', '))
        .group(:code_cell_id)
      failed.each do |result|
        results[result.code_cell_id][:failure_users] = result.failure_users
        results[result.code_cell_id][:last_failure] = result.last_failure
        results[result.code_cell_id][:last_failure_age] = result.last_failure_age
      end

      results
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

    # Health computation scaling factor.  Computations get weighted based on
    # number of users and executions.  A small number of users/executions means
    # we have less confidence in numbers like pass rate, so cells/notebooks
    # with fewer users need higher scores to be considered healthy.
    def health_scale(users, executions)
      # Each unique user counts 10x.  Full confidence around 5 users.
      x = (users - 1) * 10 + [executions, 1].max
      return 0.0 if x < 1
      return 1.0 if x > 40
      0.75 + 0.25 * Math.log(x) / Math.log(40)
    end
  end
end
