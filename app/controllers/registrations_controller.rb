# User registration controller
class RegistrationsController < Devise::RegistrationsController
  respond_to :json
  def after_sign_up_path_for(_resource_name, _resource)
    root_path
  end
end
