ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'

# :nodoc:
class ActiveSupport::TestCase # rubocop: disable Style/ClassAndModuleChildren
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# :nodoc:
class ActionController::TestCase # rubocop: disable Style/ClassAndModuleChildren
  # allow tests to use Devise and Warden
  include Devise::Test::ControllerHelpers
end
