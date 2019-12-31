# To run this script: rails runner script/create_user.rb

print 'Enter username: '
username = gets.strip
print 'Enter Email (must be valid user@domain.tld format): '
user_email = gets.strip
print 'Enter password: '
user_password = gets.strip

if username && user_password && user_email
  u = User.find_or_initialize_by(user_name: username)
  u.password = user_password
  u.email = user_email
  u.first_name = username
  u.admin = false
  u.approved = true
  u.confirmed_at = Time.current
  u.save
end
