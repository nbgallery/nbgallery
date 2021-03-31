# Make sure directories exist
%i[cache change_requests staging repo].each do |dir|
  FileUtils.mkdir_p(GalleryConfig.directories[dir])
end
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'javascripts', 'custom'))
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'stylesheets', 'custom'))
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'images', 'custom_images'))

#Otherwise passing in any value other than "true" by environment varialbe still makes this evaluate to true
if GalleryConfig.storage.track_revisions || GalleryConfig.storage.track_revisions == "true"
  GalleryConfig.storage.track_revisions = true
else
  GalleryConfig.storage.track_revisions = false
end

# Load extensions
# Note: extension configs already loaded in application.rb
GalleryLib.extensions.each do |name, info|
  Rails.logger.info("Loading extension: #{name}")

  if Rails.env.development?
    load info[:file]
  else
    require info[:file]
  end

  migrations = File.join(info[:dir], 'migrate')
  if File.exist?(migrations) # rubocop: disable Style/Next
    Rails.logger.debug("  Adding migrations for #{name}")
    # This list is what rake looks at
    ActiveRecord::Tasks::DatabaseTasks.migrations_paths.push(migrations)
    # This list is what rails looks at
    ActiveRecord::Migrator.migrations_paths.push(migrations)
  end
end

# Create stubs for optional extension files
stubs = [
  'app/views/application/_custom_upload_fields.slim',
  'app/views/application/_custom_message_fields.slim',
  'app/views/application/_custom_banner.slim',
  'app/views/application/_custom_footer.slim',
  'app/views/application/_custom_fields.slim',
  'app/views/application/_custom_buttons.slim',
  'app/views/application/_custom_links.slim',
  'app/views/application/_custom_webtracking.slim',
  'app/views/static_pages/_custom_overview_modal.slim',
  'app/views/static_pages/_custom_home_search_fields.slim',
  'app/views/application/_custom_change_request_approval_fields.slim',
  'app/views/application/_custom_change_request_warning.slim',
  'app/assets/stylesheets/custom/_custom_styles.scss',
  'app/views/application/_custom_beta_link.slim',
  'app/views/application/_custom_notebook_listing_label.slim',
  'app/views/application/_custom_table_row_heading_label.slim'
]

stubs.each do |stub|
  FileUtils.touch(Rails.root.join(stub).to_s) unless
    File.exist?(Rails.root.join(stub).to_s)
end

# Allow tables in markdown
Rails::Html::WhiteListSanitizer.allowed_tags.merge(%w[table thead tbody tr th td])

# Set up git repository for notebooks
if defined?(Rails::Server) && GalleryConfig.storage.track_revisions && !GalleryConfig.storage.database_notebooks
  begin
    Git.open(GalleryConfig.directories.repo)
    # success => repo already exists, nothing else to do
  rescue StandardError
    Rails.logger.info('Creating git repository for notebooks')
    Revision.init
  end
end
