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
      .select('notebook_id, user_id, ROUND(SUM(score), 1) as rounded_score')
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
      .select('ROUND(score*20)/20 as rounded_score, count(*) as count')
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
end
