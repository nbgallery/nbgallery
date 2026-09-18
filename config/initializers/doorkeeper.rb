Doorkeeper.configure do
  resource_owner_authenticator do
    ActiveRecord::Base.connected_to(role: :writing) do
      current_user || warden.authenticate!(scope: :user)
    end
  end
  admin_authenticator do |_routes|
    raise User::Forbidden, 'You are not allowed to view this page.' unless current_user && current_user.admin?
    current_user
  end
  default_scopes :read
  optional_scopes :write

  enforce_configured_scopes
end
