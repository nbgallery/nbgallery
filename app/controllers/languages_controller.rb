# Languages controller
class LanguagesController < ApplicationController
  before_action :set_config_notebooks, except: [:index]

  # GET /languages
  def index
    @languages = Notebook.language_counts(@user)
  end

  # GET /languages/:lang
  def show
    respond_to do |format|
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
      format.html {}
    end
  end

  # GET /languages/:lang/101
  def tutorial
    raise ActiveRecord::RecordNotFound, 'No tutorial configured for this language.' if @config[:tutorial].blank?
    @notebook = Notebook.find_by!(uuid: GalleryConfig.languages[@lang][:tutorial])
    render 'notebooks/show'
  end

  private

  def set_config_notebooks
    # Split apart language and version
    m = /(\D+)(\d*)/.match(params[:id])
    @lang = m[1]
    @version = m[2]

    # Get config and notebooks for the language.
    # If *both* are empty, throw a 404.
    @config = GalleryConfig.languages[@lang]
    @notebooks = query_notebooks.where(lang: @lang)
    @notebooks = @notebooks.where('lang_version LIKE ?', "#{@version}.%") if @version.present?
    raise ActiveRecord::RecordNotFound, 'Unknown language' if @config.nil? && @notebooks.blank?
    @notebooks = @notebooks.where("notebooks.id not in (select notebook_id from deprecated_notebooks)") unless (params[:show_deprecated] && params[:show_deprecated] == "true")
    @config = @config&.to_hash || {}

    # If link is unset, use /101 tutorial notebook if set
    @config[:link] = "#{language_path(@lang)}/101" if @config[:link].blank? && @config[:tutorial].present?

    # Merge with default settings just to be safe.
    @config.update(GalleryConfig.languages.default.to_hash) {|_key, old, new| old || new}
  end
end
