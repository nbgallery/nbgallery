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

  def feed
    @feed = Notebook
      .readable_by(@user)
      .where('updated_at > ?', 90.days.ago)
      .order(updated_at: :desc)
      .includes(:updater)
    @last_viewed = Time.at(cookies[:feed_viewed].to_i).utc
    cookies[:feed_viewed] = { value: Time.current.to_i, expires: 1.year.from_now }
  end

  def home_feed
    @feed = Notebook.readable_by(@user).order(updated_at: :desc).includes(:updater).limit(20)
    @last_viewed = Time.at(cookies[:home_viewed].to_i).utc
    render layout: false
  end

  def layout_dropdown
    render layout: false
  end

  def beta_home_notebooks
    home_notebooks
  end

  #new beta homepage layout
  def home_notebooks
    #recommendation list for the user
    if params[:type] == 'suggested' or (@user.member? and params[:type].nil?)
      @notebooks = @user.notebook_recommendations.order('score DESC').first(Notebook.per_page)
      locals = { ref: 'suggested' }
    #recent
    elsif params[:type] == 'recent' or params[:type].nil?
      @sort = :created_at
      @notebooks = query_notebooks
      locals = { ref: 'home_recent' }
    #newsfeed
    elsif params[:type] == 'updated'
      @sort = :updated_at
      @notebooks = query_notebooks
      locals = { ref: 'updated' }
    #USER notebooks
    elsif params[:type] == 'mine'
      @sort = :updated_at
      @notebooks = query_notebooks.where(
        "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
        @user.id,
        @user.id,
        @user.id
      )
      locals = { ref: 'home_updated' }
    #a list of all notebooks
    elsif params[:type] == 'all'
      @notebooks = query_notebooks
      locals = { ref: 'all' }
    #starred notebooks
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
