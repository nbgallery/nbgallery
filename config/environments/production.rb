Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true
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
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  # TODO not sure if this workaround is still needed:
  #config.assets.js_compressor = :uglifier # crashes in uglifier 4 (invalid option :copyright)
  config.assets.js_compressor = Uglifier.new(harmony:true)
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]
  
	# Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  #Rails defauilts to info for production, but leaving this statement here if you ever neeed to turn up the log level on production
  config.log_level = :debug

  #Use Lograge to consolodate and timestamp some of the logs for easier reading/parsing
#  config.lograge.enabled = true
#  config.lograge.custom_options = lambda do |event|
#    { time: Time.now }

  # Prepend all log lines with the following tags.
  # config.log_tags = [ :request_id ]

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

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "railsdiff_#{Rails.env}"

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST'] }
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

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
