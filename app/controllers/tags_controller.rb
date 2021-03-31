# Controller for tag pages
class TagsController < ApplicationController
  before_action :set_tag, only: [:show]

  # GET /tags
  def index
    @tags = Tag.readable_by(@user)
    respond_to do |format|
      format.html
      format.json {render json: @tags.map {|tag| tag[0]}}
    end
  end

  # GET /tags/:tag
  def show
    @notebooks = query_notebooks
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
      .where('tags.tag = ?', @tag.tag)
    @notebooks = @notebooks.where("notebooks.id not in (select notebook_id from deprecated_notebooks)") unless (params[:show_deprecated] && params[:show_deprecated] == "true")
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tag
    @tag = Tag.find_by!(tag: params[:id])
  end
end
