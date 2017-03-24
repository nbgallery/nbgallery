# Controller for admin pages
class AdminController < ApplicationController
  before_action :verify_admin

  # GET /admin
  def index
    # Links to other admin pages
  end

  # GET /admin/internal
  def internal
    # Ruby internal state
    @internal = {
      garbage_collection: GC.stat,
      threads: Thread.list.map {|thr| [thr.inspect[2...-1], thr.backtrace.first]}
    }
    respond_to do |format|
      format.html
      format.json {render json: @internal}
    end
  end

  # GET /admin/suggestions
  def suggestions
    # Summarize results of the suggestion engine
    reason_select = [
      'count(1) as count',
      'avg(score) as mean',
      'stddev(score) as stddev',
      'min(score) as min',
      'max(score) as max',
      'reason'
    ].join(', ')

    @suggestions = {
      total_notebooks: Notebook.count,
      total_users: User.count,
      total_suggestions: SuggestedNotebook.count,
      num_notebooks_suggested: SuggestedNotebook.group(:notebook_id).count.count,
      num_users_with_suggestions: SuggestedNotebook.group(:user_id).count.count,
      reasons: SuggestedNotebook.select(reason_select).group(:reason).order('count DESC'),
      most_suggested_notebooks:
        SuggestedNotebook.group(:notebook).count.sort_by {|_nb, count| -count}.take(50),
      users_with_most_suggestions:
        SuggestedNotebook.group(:user).count.sort_by {|_nb, count| -count}.take(50),
      most_suggested_groups:
        SuggestedGroup.group(:group).count.sort_by {|_group, count| -count}.take(25),
      most_suggested_tags:
        SuggestedTag.group(:tag).count.sort_by {|_tag, count| -count}.take(25)
    }
    respond_to do |format|
      format.html
      format.json {render json: @suggestions}
    end
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
end
