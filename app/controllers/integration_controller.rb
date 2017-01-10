# Controller for tag pages
class IntegrationController < ApplicationController
  # GET integration/gallery_common
  def gallery_common
    respond_to do |format|
      format.js {}
    end
    render layout: false
  end

  # GET integration/gallery_tree
  def gallery_tree
    respond_to do |format|
      format.js {}
    end
    render layout: false
  end

  # GET integration/gallery_notebook
  def gallery_notebook
    respond_to do |format|
      format.js {}
    end
    render layout: false
  end
end
