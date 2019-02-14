# Run with rails runner script/run_job.rb

if ARGV.empty? || ARGV[0].empty?
  puts 'need job name'
else
  ScheduledJobs.run(ARGV[0].to_sym)
end
