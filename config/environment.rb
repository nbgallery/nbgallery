# Load the Rails application.

libs = File.expand_path('../lib', __dir__)

Dir["#{libs}/*.rb"].each do |lib|
  require lib
end

require File.expand_path('application', __dir__)

Encoding.default_internal = Encoding::UTF_8
Encoding.default_external = Encoding::UTF_8

# Initialize the Rails application.
Rails.application.initialize!
