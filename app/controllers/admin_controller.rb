# Controller for admin pages
class AdminController < ApplicationController
  before_action :verify_admin

  # GET /admin
  def index
    # Links to other admin pages
  end

  # GET /admin/recommender_summary
  def recommender_summary
    @total_notebooks = Notebook.count
    @total_users = User.count
    @total_recommendations = SuggestedNotebook.count
    @notebooks_recommended = SuggestedNotebook.group(:notebook_id).count.count
    @user_with_recommendations = SuggestedNotebook.group(:user_id).count.count

    @reasons = SuggestedNotebook
      .select(reason_select)
      .group(:reason)
      .order('count DESC')

    @most_suggested_notebooks = SuggestedNotebook
      .group(:notebook)
      .order('count_all DESC')
      .limit(50)
      .count

    @users_with_most_suggestions = SuggestedNotebook
      .group(:user)
      .order('count_all DESC')
      .limit(50)
      .count

    @most_suggested_groups = SuggestedGroup
      .group(:group)
      .order('count_all DESC')
      .limit(25)
      .count

    @most_suggested_tags = SuggestedTag.top(:tag, 25)

    @scores = SuggestedNotebook
      .select('notebook_id, user_id, TRUNCATE(SUM(score), 1) as rounded_score')
      .group('notebook_id, user_id')
      .map(&:rounded_score)
      .group_by(&:to_f)
      .map {|score, arr| [score, arr.count]}
      .sort_by {|score, _count| score}
  end

  # GET /admin/recommender
  def recommender
    @reason = params[:reason]

    @notebooks = SuggestedNotebook
      .where(reason: @reason)
      .group(:notebook)
      .order('count_all DESC')
      .limit(25)
      .count
    @notebook_count = SuggestedNotebook
      .where(reason: @reason)
      .select(:notebook_id)
      .distinct
      .count

    @users = SuggestedNotebook
      .where(reason: @reason)
      .group(:user)
      .order('count_all DESC')
      .limit(25)
      .count
    @user_count = SuggestedNotebook
      .where(reason: @reason)
      .select(:user_id)
      .distinct
      .count

    # Scores grouped into 0.05-sized bins
    @scores = SuggestedNotebook
      .where(reason: @reason)
      .select('FLOOR(score*20)/20 as rounded_score, count(*) as count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
      .to_h
    (0..20).each {|i| @scores[i / 20.0] ||= 0.0} # fill in gaps with 0.0
    @scores = @scores.to_a.sort_by {|score, _count| score}

    @distribution = SuggestedNotebook
      .where(reason: @reason)
      .select(reason_select)
      .first
  end

  # GET /admin/trendiness
  def trendiness
    @total_notebooks = Notebook.count
    @nonzero_trendiness = NotebookSummary.where('trendiness > 0.0').count

    @scores = NotebookSummary
      .where('trendiness > 0.0')
      .select('FLOOR(trendiness*20)/20 AS rounded_score, COUNT(*) AS count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
      .to_h
    (0..20).each {|i| @scores[i / 20.0] ||= 0.0} # fill in gaps with 0.0
    @scores = @scores.to_a.sort_by {|score, _count| score}

    @notebooks = NotebookSummary
      .includes(:notebook)
      .order(trendiness: :desc)
      .take(25)
      .map(&:notebook)
  end

  # GET /admin/health
  def health
    @execs = exec_helper(nil, false)
    @execs_last30 = exec_helper(nil, true)
    @execs_pass = exec_helper(true, false)
    @execs_pass_last30 = exec_helper(true, true)
    @execs_fail = exec_helper(false, false)
    @execs_fail_last30 = exec_helper(false, true)

    @total_code_cells = CodeCell.count
    @cell_execs = cell_exec_helper(nil, false)
    @cell_execs_fail = cell_exec_helper(true, false)
    @cell_execs_last30 = cell_exec_helper(nil, true)
    @cell_execs_fail_last30 = cell_exec_helper(true, true)

    @total_notebooks = Notebook.count
    @notebook_execs = notebook_exec_helper(nil, false)
    @notebook_execs_fail = notebook_exec_helper(true, false)
    @notebook_execs_last30 = notebook_exec_helper(nil, true)
    @notebook_execs_fail_last30 = notebook_exec_helper(true, true)

    @lang_by_day = Execution
      .joins(:code_cell, :notebook)
      .where('executions.updated_at > ?', 30.days.ago)
      .select([
        'count(distinct(notebooks.id)) AS count',
        'notebooks.lang AS lang',
        'DATE(executions.updated_at) AS day'
      ].join(','))
      .group('lang, day')
      .order('day, lang')
      .group_by(&:lang)
      .map {|lang, entries| { name: lang, data: entries.map {|e| [e.day, e.count]} }}

    @users_by_day = Execution
      .joins(:code_cell)
      .where('executions.updated_at > ?', 30.days.ago)
      .select('COUNT(DISTINCT(user_id)) AS count, DATE(executions.updated_at) AS day')
      .group('day')
      .map {|e| [e.day, e.count]}
      .sort_by {|day, _count| day}

    @success_by_cell_number = Execution
      .joins(:code_cell)
      .where('executions.updated_at > ?', 30.days.ago)
      .select('COUNT(*) AS count, success, code_cells.cell_number AS cell_number')
      .group('success, cell_number')
      .order('cell_number')
      .group_by(&:success)
      .sort_by {|success, _entries| success ? 0 : 1}
      .map do |success, entries|
        {
          name: success ? 'success' : 'failure',
          data: entries.map {|e| [e.cell_number, e.count]}
        }
      end

    @runtime_by_cell_number = Execution
      .joins(:code_cell)
      .where('executions.updated_at > ?', 30.days.ago)
      .select('AVG(runtime) AS runtime, code_cells.cell_number')
      .group('cell_number')
      .map {|e| [e.cell_number, e.runtime]}
      .sort_by {|cell_number, _runtime| cell_number}

    @recently_run = Notebook
      .joins(:executions)
      .select('notebooks.*, MAX(executions.updated_at) AS last_exec')
      .group('notebooks.id')
      .order('last_exec DESC')
      .limit(20)

    @recently_failed = Notebook
      .joins(:executions)
      .where('executions.success = 0')
      .select('notebooks.*, MAX(executions.updated_at) AS last_failure')
      .group('notebooks.id')
      .order('last_failure DESC')
      .limit(20)
  end

  # GET /admin/user_similarity
  def user_similarity
    # Top similarity scores
    @similar_users = UserSimilarity.includes(:user, :other_user)
      .where('user_id < other_user_id')
      .order(score: :desc)
      .paginate(page: @page, per_page: @per_page || 1000)
    respond_to do |format|
      format.html
      format.json {render json: @similar_users}
    end
  end

  # GET /admin/notebook_similarity
  def notebook_similarity
    # Top similarity scores
    @similar_notebooks = NotebookSimilarity.includes(:notebook, :other_notebook)
      .where('notebook_id < other_notebook_id')
      .order(score: :desc)
      .paginate(page: @page, per_page: @per_page || 1000)
    respond_to do |format|
      format.html
      format.json {render json: @similar_notebooks}
    end
  end

  # GET /admin/packages
  def packages
    @packages = Notebook.package_summary
  end

  # GET /admin/exception
  def exception
    blah = nil
    render json: blah.stuff
  end

  # GET /admin/notebooks
  def notebooks
    notebooks_info =  Notebook.includes(:creator).group(:creator).count
    total_notebooks = 0
    notebooks_info.each do |_key, value|
      total_notebooks += value
    end
    @total_notebooks = total_notebooks
    @total_authors = notebooks_info.count
    @public_count = Notebook.where('public=true').count
    @private_count = Notebook.where('public=false').count
    @notebooks_info = notebooks_info.sort_by {|_user, num| -num}
  end

  private

  def reason_select
    [
      'count(1) as count',
      'avg(score) as mean',
      'stddev(score) as stddev',
      'min(score) as min',
      'max(score) as max',
      'reason'
    ].join(', ')
  end

  def exec_helper(success, last30)
    relation = Execution
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('updated_at > ?', 30.days.ago) if last30
    relation.count
  end

  def cell_exec_helper(success, last30)
    relation = Execution
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('executions.updated_at > ?', 30.days.ago) if last30
    relation.select(:code_cell_id).distinct.count
  end

  def notebook_exec_helper(success, last30)
    relation = Execution.joins(:code_cell)
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('executions.updated_at > ?', 30.days.ago) if last30
    relation.select(:notebook_id).distinct.count
  end
end
