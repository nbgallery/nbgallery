class ResourcesController < ApplicationController
  before_action(:verify_login)
  before_action(:set_resource)
  before_action(:verify_edit_or_admin)

  # DELETE /resources/:id
  def destroy
    @resource.destroy()
    head :no_content
  end

  def set_resource()
    @resource = Resource.find_by('id': params[:id])
    @notebook = Notebook.find_by('id' => @resource.notebook_id)
    flash[:success] = GalleryConfig.external_resources_label + " successfully deleted."
  end
end
