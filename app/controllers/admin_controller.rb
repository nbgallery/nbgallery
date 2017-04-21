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
    @users_with_recommendations = SuggestedNotebook.group(:user_id).count.count

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

    @user_notebook_scores = SuggestedNotebook
      .includes(:notebook, :user)
      .select([
        'notebook_id',
        'user_id',
        SuggestedNotebook.reasons_sql,
        SuggestedNotebook.score_sql
      ].join(', '))
      .group('notebook_id, user_id')
      .order('score DESC')
      .limit(25)
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
    @scores = GalleryLib.chart_prep(@scores, keys: (0..20).map {|i| i / 20.0})

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
    @scores = GalleryLib.chart_prep(@scores, keys: (0..20).map {|i| i / 20.0})

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
      .languages_by_day
      .map {|lang, entries| { name: lang, data: entries }}
    @lang_by_day = GalleryLib.chart_prep(@lang_by_day)

    @users_by_day = Execution.users_by_day

    @success_by_cell_number = execution_success_chart(
      Execution,
      'code_cells.cell_number',
      :cell_number
    )

    @recently_executed = Notebook.recently_executed.limit(20)
    @recently_failed = Notebook.recently_failed.limit(20)

    # Graph with x = fail rate, y = cells with fail rate >= x
    @cumulative_fail_rates = CodeCell.cumulative_fail_rates
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
