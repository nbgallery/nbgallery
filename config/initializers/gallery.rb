# Make sure directories exist
[:cache, :change_requests, :staging, :wordclouds].each do |dir|
  FileUtils.mkdir_p(GalleryConfig.directories[dir])
end
FileUtils.mkdir_p(File.join(Rails.root.join('app', 'assets', 'javascripts', 'custom')))
FileUtils.mkdir_p(File.join(Rails.root.join('app', 'assets', 'stylesheets', 'custom')))

# Load extensions
GalleryConfig.directories.extensions.each do |extension_dir|
  Dir["#{extension_dir}/*/*.rb"].each do |extension|
    dir = File.basename(File.dirname(extension))
    file = File.basename(extension, '.rb')
    next unless dir == file

    Rails.logger.info("Loading extension: #{file}")
    load extension

    migrations = File.join(File.dirname(extension), 'migrate')
    if File.exist?(migrations)
      Rails.logger.debug("  Adding migrations for #{file}")
      # This list is what rake looks at
      ActiveRecord::Tasks::DatabaseTasks.migrations_paths.push(migrations)
      # This list is what rails looks at
      ActiveRecord::Migrator.migrations_paths.push(migrations)
    end

    config = File.join(File.dirname(extension), "#{file}.yml")
    GalleryConfig.add_source!(config) if File.exist?(config)
  end
end

# Reload settings to fold in extension config files
GalleryConfig.reload!

# Create stubs for optional extension files
stubs = [
  'app/views/application/_custom_upload_fields.slim',
  'app/views/application/_custom_message_fields.slim',
  'app/views/application/_custom_banner.slim',
  'app/views/application/_custom_footer.slim',
  'app/views/application/_custom_fields.slim',
  'app/views/application/_custom_buttons.slim',
  'app/views/static_pages/_custom_overview_modal.slim',
  'app/views/application/_custom_change_request_approval_fields.slim',
  'app/views/application/_custom_change_request_warning.slim',
  'app/assets/stylesheets/custom/_custom_styles.scss'
]

stubs.each do |stub|
  FileUtils.touch(Rails.root.join(stub).to_s) unless
    File.exist?(Rails.root.join(stub).to_s)
end

# Allow tables in markdown
Rails::Html::WhiteListSanitizer.allowed_tags.merge(%w(table thead tbody tr th td))
