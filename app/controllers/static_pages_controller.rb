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
    @feed = Click.feed(@user)
    @last_viewed = Time.at(cookies[:feed_viewed].to_i).utc
    cookies[:feed_viewed] = { value: Time.current.to_i, expires: 1.year.from_now }
  end

  def home_feed
    @feed = Click.includes(:notebook, :user).feed(@user).first(20)
    @last_viewed = Time.at(cookies[:home_viewed].to_i).utc
    render layout: false
  end

  def layout_dropdown
    render layout: false
  end

  def home_notebooks
    if params[:type] == 'suggested' or (@user.member? and params[:type].nil?)
      @notebooks = @user.notebook_recommendations.order('score DESC').first(5)
      locals = { ref: 'suggested' }
    elsif params[:type] == 'recent' or params[:type].nil?
      @notebooks = Notebook.readable_by(@user).order('created_at DESC').first(5)
      locals = { ref: 'home_recent' }
    elsif params[:type] == 'updated'
      @notebooks = Notebook.readable_by(@user).order('updated_at DESC').first(5)
      locals = { ref: 'home_updated' }
    end
    render layout: false, locals: locals
  end

  def rss
    @feed = Click.feed(@user)
    render layout: false, content_type: 'application/rss+xml'
  end

  def robots
    # Block crawl of the alpha testing site
    if request.base_url.include?('alpha-gallery') || ENV['GALLERY_NO_CRAWL']
      render layout: false, text: "User-agent: *\nDisallow: /"
      return
    end
    @notebooks = Notebook.readable_by(@user)
    render layout: false
  end
end
