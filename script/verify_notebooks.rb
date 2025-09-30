# To run this script: rails runner script/verify_notebooks.rb

puts "Verifying notebooks not properly verified..."

notebooks = Notebook.all
notebook_total = notebooks.length
notebook_count = 0

notebooks.each do |nb|
  print "Setting Verification for #{nb.title}..."
  nb.set_verification(nb.review_status == :full)
  nb.save! if nb.changed?
  notebook_count = notebook_count + 1
  puts "Done (#{notebook_count}/#{notebook_total})"
end

puts "Complete"
