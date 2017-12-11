# Stub interface for user authentication
class AuthenticationService
  # Authenticate and return user object
  def self.authenticate_user(_request, _response)
    User.new
  end
end
