# Static pages controller
class StaticPagesController < ApplicationController
  @@home_id = ""
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
    # Recommended Notebooks
    if (params[:type] == 'suggested' or params[:type].nil?) and @user.member?
      @notebooks = @user.notebook_recommendations.order('score DESC').first(Notebook.per_page)
      @@home_id = 'suggested'
    # All Notebooks
    elsif params[:type] == 'all' or params[:type].nil?
      @notebooks = query_notebooks
      @@home_id = 'all'
    # Recent Notebooks
    elsif params[:type] == 'recent'
      @sort = :created_at
      @notebooks = query_notebooks
      @@home_id = 'home_recent'
    # User's Notebooks
    elsif params[:type] == 'mine' and @user.member?
      @sort = :updated_at
      @notebooks = query_notebooks.where(
        "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
        @user.id,
        @user.id,
        @user.id
      )
      @@home_id = 'home_updated'
    # Starred Notebooks
    elsif params[:type] == 'stars'
      @notebooks = query_notebooks.where(id: @user.stars.pluck(:id))
      @@home_id = 'stars'
    end
    locals = { ref: @@home_id }
    @@home_id = @@home_id.gsub("_"," ").split.map(&:capitalize).join('')
    @@home_id[0] = @@home_id[0].downcase
    render layout: false, locals: locals
  end

  def setup_home_id
    return @@home_id
  end
  helper_method :setup_home_id

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
