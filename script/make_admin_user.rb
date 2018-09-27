# To run this script: rails runner script/make_admin_user.rb

print 'Enter username: '
user_name = gets.strip
user = User.find_by(user_name: user_name)

if user
  puts 'Found user:'
  puts "  id   : #{user.id}"
  puts "  name : #{user.name}"
  puts "  email: #{user.email}"
  print 'Make this user admin? (y/n): '
  confirm = gets
  if confirm.present? && confirm[0].casecmp('y').zero?
    user.admin = true
    user.save!
    puts 'Done!'
  end
else
  puts "Couldn't find a user with that username!"
  puts 'Please create the account through the web UI first.'
end
