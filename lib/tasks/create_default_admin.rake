desc 'Create an admin account from environment variables'
task :create_default_admin  => :environment do
  # Create an admin user at startup if specified
  $rails_rake_task = true
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
end
