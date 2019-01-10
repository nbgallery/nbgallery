# Add additional schedule to what's defined in config/cronic.d/jobs.rb.
# See job_files in lib/scheduled_jobs.rb for how this gets loaded.
unless self.class == Object # avoid Rails autoload
  every '1h' do
    ScheduledJobs.run(:backup)
  end
end
