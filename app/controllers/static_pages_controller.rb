# Static pages controller
class StaticPagesController < ApplicationController
  def home
    cookies[:home_viewed] = { value: Time.current.to_i, expires: 1.year.from_now }
  end

  def help
  end

  def faq
  end

  def video
  end

  def layout_dropdown
    render layout: false
  end

  def beta_home_notebooks
    home_notebooks
  end

  # Homepage Layout
  def home_notebooks
    # Recommendation list for the user
    if (params[:type] == 'suggested' or params[:type].nil?) and @user.member?
      @notebooks = @user.notebook_recommendations.order('score DESC').first(Notebook.per_page)
      locals = { ref: 'suggested' }
    # List of all notebooks
    elsif params[:type] == 'all' or params[:type].nil?
      @notebooks = query_notebooks
      locals = { ref: 'all' }
    # Recent
    elsif params[:type] == 'recent'
      @sort = :created_at
      @notebooks = query_notebooks
      locals = { ref: 'home_recent' }
    # Newsfeed
    #elsif params[:type] == 'updated'
      #@sort = :updated_at
      #@notebooks = query_notebooks
      #locals = { ref: 'updated' }
    # User's notebooks
    elsif params[:type] == 'mine' and @user.member?
      @sort = :updated_at
      @notebooks = query_notebooks.where(
        "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
        @user.id,
        @user.id,
        @user.id
      )
      locals = { ref: 'home_updated' }
    # Starred notebooks
    elsif params[:type] == 'stars'
      @notebooks = query_notebooks.where(id: @user.stars.pluck(:id))
      locals = { ref: 'stars' }
    end
    render layout: false, locals: locals
  end

  def beta_notebook
    if params[:type] == 'learning'
      @notebook = Notebook.find(GalleryConfig.learning.landing_id)
    end
    render layout: false
  end

  def robots
    # Block crawl of test sites
    block_crawl =
      request.base_url.include?('alpha') ||
      request.base_url.include?('test') ||
      ENV['GALLERY_NO_CRAWL']
    if block_crawl
      render layout: false, text: "User-agent: *\nDisallow: /"
      return
    end
    @notebooks = Notebook.readable_by(@user)
    render layout: false
  end
end
