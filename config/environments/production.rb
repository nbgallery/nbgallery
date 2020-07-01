Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Enable Rack::Cache to put a simple HTTP cache in front of your application
  # Add `rack-cache` to your Gemfile before enabling this.
  # For large-scale production use, consider using a caching reverse proxy like
  # NGINX, varnish or squid.
  # config.action_dispatch.rack_cache = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.serve_static_files = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  # TODO not sure if this workaround is still needed:
  #config.assets.js_compressor = :uglifier # crashes in uglifier 4 (invalid option :copyright)
  config.assets.js_compressor = Uglifier.new
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  #Rails defauilts to info for production, but leaving this statement here if you ever neeed to turn up the log level on production
  #config.log_level = :debug

  #Use Lograge to consolodate and timestamp some of the logs for easier reading/parsing
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    { time: Time.now }

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  Rails.application.routes.default_url_options[:host] = ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST']
  #config.routes.default_url_options[:host] = ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST']
  config.action_mailer.default_url_options = { host: ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST'] }
  if ENV['EMAIL_SERVER'].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV['EMAIL_SERVER'],
      domain: ENV['EMAIL_DOMAIN'],
      port: 587,
      user_name: ENV['EMAIL_USERNAME'],
      password: ENV['EMAIL_PASSWORD'],
      authentication: :login
    }
  end

  # Exception notification
  if GalleryConfig.email.exceptions_to.present?
    config.middleware.use(
      ExceptionNotification::Rack,
      email: {
        deliver_with: :deliver,
        email_prefix: "[#{GalleryConfig.site.name} Error]",
        sender_address: GalleryConfig.email.exceptions_from,
        exception_recipients: GalleryConfig.email.exceptions_to,
        sections: %w[request backtrace session]
      }
    )
  end
end
