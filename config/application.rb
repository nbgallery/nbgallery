require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'active_record/connection_adapters/mysql2_adapter'
require_relative '../lib/gallery_lib'

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
    GalleryLib.extensions.each do |name, info|
      next unless info[:config]
      puts "Loading extension config: #{name}.yml" # rubocop: disable Rails/Output
      config_files << info[:config].to_s
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
        resource '/preferences', header: :any, methods: %i[post options]
        resource '/environments', header: :any, methods: %i[post options patch get]
        resource '/notebooks/*/metadata', headers: :any, methods: %i[get options]
        resource '/notebooks/*/diff', headers: :any, methods: %i[post options patch get]
        resource '/notebooks/*/download', headers: :any, methods: %i[get]
        resource '/nb/*/uuid', headers: :any, methods: %i[get]
        resource '/change_requests/*/download', headers: :any, methods: %i[get]
        resource '/stages', headers: :any, methods: %i[post options]
        resource '/integration/*', headers: :any, methods: %i[get]
        resource '/executions', headers: :any, methods: %i[post]
      end
      GalleryConfig.dig(:extensions, :cors)&.each do |cors|
        allow do
          origins cors.origins
          cors.resources.each do |r|
            resource r.pattern, headers: r.headers.to_sym, methods: r.method_list.map(&:to_sym)
          end
        end
      end
    end

    config.encoding = 'utf-8'

    # Set up extension system
    GalleryConfig.directories.extensions.each do |dir|
      config.eager_load_paths += Dir[File.join(dir, '*')]
    end
    config.eager_load_paths << Rails.root.join('lib', 'extension_points')
  end
end
