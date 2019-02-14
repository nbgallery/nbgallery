if defined?(Rails::Server)
  if Rails.env.production? && defined?(PhusionPassenger)
    Rails.logger.info('Passenger detected - jobs should be run by cronic script')
  elsif !GalleryConfig.scheduler.internal
    Rails.logger.info('Internal scheduler disabled - jobs should be run by cronic script')
  else
    scheduler = Rufus::Scheduler.start_new
    ScheduledJobs.job_files.each do |file|
      Rails.logger.info("SCHEDULER: loading #{file}")
      scheduler.instance_eval(IO.read(file))
    end
  end
end
