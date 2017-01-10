# This file is used by Rack-based servers to start the application.

# Workaround for using puma instead of 'rails server'
module Rails
  class Server
  end
end


require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
