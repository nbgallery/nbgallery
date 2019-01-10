# Class to define backup code
class Backup
  # Code to do the actual backup goes here
  def run
  end
end

# Add a job function to the ScheduledJobs class
ScheduledJobs.class_eval do
  # This function can be executed via ScheduledJobs.run(:backup)
  def self.backup
    Backup.new.run
  end
end
