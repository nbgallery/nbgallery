class RegistrationsController < Devise::RegistrationsController  
  respond_to :json
  def after_sign_up_path_for(resource_name, resource)
    root_path
  end
end  
