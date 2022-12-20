# This file is used by Rack-based servers to start the application.

# Workaround for using puma instead of 'rails server'
module Rails
  class Server
  end
end


require_relative 'config/environment'
map JupyterGallery::Application.config.relative_url_root || '/' do
  run Rails.application
end
