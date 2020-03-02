# Make sure directories exist
%i[cache change_requests staging wordclouds repo].each do |dir|
  FileUtils.mkdir_p(GalleryConfig.directories[dir])
end
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'javascripts', 'custom'))
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'stylesheets', 'custom'))
FileUtils.mkdir_p(Rails.root.join('app', 'assets', 'images', 'custom_images'))

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
  'app/views/application/_custom_change_request_approval_fields.slim',
  'app/views/application/_custom_change_request_warning.slim',
  'app/assets/stylesheets/custom/_custom_styles.scss',
  'app/views/application/_custom_beta_link.slim'
]

stubs.each do |stub|
  FileUtils.touch(Rails.root.join(stub).to_s) unless
    File.exist?(Rails.root.join(stub).to_s)
end

# Allow tables in markdown
Rails::Html::WhiteListSanitizer.allowed_tags.merge(%w[table thead tbody tr th td])

# Create an admin user at startup if specified
admin_user = ENV['NBGALLERY_ADMIN_USER'].presence
admin_password = ENV['NBGALLERY_ADMIN_PASSWORD'].presence
admin_email = ENV['NBGALLERY_ADMIN_EMAIL'].presence

if admin_user && admin_password && admin_email
  u = User.find_or_initialize_by(user_name: admin_user)
  u.password = admin_password
  u.email = admin_email
  u.first_name = 'Admin'
  u.admin = true
  u.approved = true
  u.confirmed_at = Time.current
  u.save
end

# Set up git repository for notebooks
if defined?(Rails::Server) && GalleryConfig.storage.track_revisions
  begin
    Git.open(GalleryConfig.directories.repo)
    # success => repo already exists, nothing else to do
  rescue StandardError
    Rails.logger.info('Creating git repository for notebooks')
    Revision.init
  end
end
