# To run this script: rails runner script/verify_notebooks.rb

puts "Verifying notebooks not properly verified..."

Notebook.find_each do |nb|
  nb.set_verification(nb.review_status == :full)
  nb.save! if nb.changed?
end

puts "Complete"
