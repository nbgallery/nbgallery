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

  def beta_notebook
    if params[:type] == 'learning'
      @notebook = Notebook.find(GalleryConfig.learning.landing_id)
    end
    render layout: false
  end

  def opensearch
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
