# Controller for tag pages
class TagsController < ApplicationController
  before_action :set_tag, only: [:show]

  # GET /tags
  def index
    @tag_text_with_counts = Tag.readable_by(@user, nil, params[:show_deprecated])
  end

# TODO: #360 - Fix when tag is normalized
  # GET /tags/:tag
  def show
    @notebooks = query_notebooks
      .joins('LEFT OUTER JOIN tags ON notebooks.id = tags.notebook_id')
      .where('tags.tag = ?', @tag.tag_text)
    @notebooks = @notebooks.where("deprecated=False") unless (params[:show_deprecated] && params[:show_deprecated] == "true")
    @notebooks = @notebooks.where(verified: true) unless (!params[:show_verified] || params[:show_verified] != "true")
    @notebooks = @notebooks.where(unapproved: false) unless (params[:show_unapproved] && params[:show_unapproved] == "true")
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  # TODO: #360 - Fix when tag is normalized
  def set_tag
    @tag = Tag.find_by!(tag: params[:id])
  end
end
