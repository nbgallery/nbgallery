# To run this script: rails runner script/verify_notebooks.rb

puts "Verifying notebooks not properly verified..."

Notebook.find_each do |nb|
  nb.update_verification
  nb.save if nb.changed?
end

puts "Complete"
