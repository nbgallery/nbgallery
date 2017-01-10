# Hello world at startup
self.in '1s' do
  ScheduledJobs.run(:hello)
end

# Age off
every '1h', first_in: '10m' do
  ScheduledJobs.run(:age_off)
end

# Notebook click summaries
every '4h', first_in: '10s' do
  ScheduledJobs.run(:notebook_summaries)
end

# Notebook suggestions
if Rails.env.production?
  # Run at 4am daily
  cron '0 4 * * * UTC' do
    ScheduledJobs.run(:nightly_computation)
  end
elsif Notebook.count.nonzero? && (SuggestedNotebook.count.zero? || SuggestedNotebook.pluck(:updated_at).max < 8.hours.ago)
  self.in '30s' do
    ScheduledJobs.run(:nightly_computation)
  end
end
