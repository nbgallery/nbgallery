# To run this script: rails runner script/verify_notebooks.rb

puts "Verifying notebooks not properly verified..."

Notebook.find_each do |nb|
  if nb.review_status == :full
    nb.toggle_verification
    nb.save if nb.changed?
  end
end

puts "Complete"
