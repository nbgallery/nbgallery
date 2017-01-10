# Stub interface for user authentication
class AuthenticationService
  # Authenticate and return user object
  def self.authenticate_user(_request)
    User.new
  end
end
