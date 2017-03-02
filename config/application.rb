require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_record/connection_adapters/mysql2_adapter'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# :nodoc:
module JupyterGallery
  # :nodoc:
  class Application < Rails::Application
    # Preload the Gallery configuration
    Config::Integrations::Rails::Railtie.preload

    # Load configuration from extensions.
    # Extension config files override default settings files but
    # are overridden by local settings files.
    config_files = [
      Rails.root.join('config', 'settings.yml').to_s,
      Rails.root.join('config', 'settings', "#{Rails.env}.yml").to_s,
      Rails.root.join('config', 'environments', "#{Rails.env}.yml").to_s
    ]
    GalleryConfig.directories.extensions.each do |extension_dir|
      Dir["#{extension_dir}/*/*.yml"].each do |extension|
        dir = File.basename(File.dirname(extension))
        file = File.basename(extension, '.yml')
        next unless dir == file

        puts "Loading extension config: #{file}.yml" # rubocop: disable Rails/Output
        config_files << Rails.root.join(extension).to_s
      end
    end
    config_files += [
      Rails.root.join('config', 'settings.local.yml').to_s,
      Rails.root.join('config', 'settings', "#{Rails.env}.local.yml").to_s,
      Rails.root.join('config', 'environments', "#{Rails.env}.local.yml").to_s
    ]
    GalleryConfig.reload_from_files(*config_files)

    # Some versions of MariaDB default to utf8mb4 encoding.  That makes the
    # max varchar that can be unique-indexed 190 instead of 255.
    db_config = Rails.configuration.database_configuration[Rails.env]
    conn = Mysql2::Client.new(db_config)
    results = conn.query("show variables like 'character_set_server'", as: :array)
    if results.first && results.first[1] == 'utf8mb4'
      ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:string][:limit] = 190
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    config.generators do |g|
      g.template_engine :slim
    end

    config.middleware.insert_before 0, 'Rack::Cors' do
      allow do
        origins '*'
        resource '/preferences', header: :any, methods: [:post, :options]
        resource '/environments', header: :any, methods: [:post, :options, :patch, :get]
        resource '/notebooks/*/metadata', headers: :any, methods: [:get, :options]
        resource '/notebooks/*/diff', headers: :any, methods: [:post, :options, :patch, :get]
        resource '/notebooks/*/download', headers: :any, methods: [:get]
        resource '/nb/*/uuid', headers: :any, methods: [:get]
        resource '/change_requests/*/download', headers: :any, methods: [:get]
        resource '/stages', headers: :any, methods: [:post, :options]
        resource '/integration/*', headers: :any, methods: [:get]
        resource '/executions', headers: :any, methods: [:post]
      end
    end

    config.encoding = 'utf-8'

    # Set up extension system
    GalleryConfig.directories.extensions.each do |dir|
      config.eager_load_paths += Dir[File.join(dir, '*')]
    end
    config.eager_load_paths << File.join(Rails.root, 'lib', 'extension_points')
  end
end
