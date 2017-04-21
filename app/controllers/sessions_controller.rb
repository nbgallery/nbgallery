# User session controller
class SessionsController < Devise::SessionsController
  respond_to :json
end
