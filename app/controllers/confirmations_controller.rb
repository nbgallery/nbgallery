# User confirmation controller
class ConfirmationsController < Devise::ConfirmationsController
  respond_to :json
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:success, :confirmed)
    else
      set_flash_message!(:error, 'You have already been confirmed')
    end
    respond_with_navigational(resource) {redirect_to after_confirmation_path_for(resource_name, resource)}
  end
end
