Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  config.action_mailer.perform_deliveries = true

  config.action_mailer.default_url_options = { host: 'localhost:3000' }
  if ENV['EMAIL_SERVER'].present?
    mail_port=587
    if ENV['EMAIL_PORT'].present? && ENV['EMAIL_PORT'].length > 0
      mail_port=ENV['EMAIL_PORT']
    end
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['EMAIL_SERVER'],
      domain: ENV['EMAIL_DOMAIN'],
      port: mail_port
    }
    if ENV['EMAIL_USERNAME'].present? && ENV['EMAIL_USERNAME'].length > 0
      config.action_mailer.smtp_settings[:user_name] = ENV['EMAIL_USERNAME']
      config.action_mailer.smtp_settings[:password] = ENV['EMAIL_PASSWORD']
      config.action_mailer.smtp_settings[:authentication] = :login
    end
  end

  # Run embedded solr.
  # Set this to false if you're running your own solr instance in dev
  config.run_solr = true
  config.run_solr = false if ENV['RUN_SOLR'] == 'false'

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
end

require 'dotenv'
Dotenv.load
