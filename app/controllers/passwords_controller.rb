# User password controller
class PasswordsController < Devise::PasswordsController
  respond_to :json
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      render json: { success: true }
    else
      render json: { success: false, errors: resource.errors }, status: :internal_server_error
    end
  end
end
