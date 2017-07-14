# Hello world at startup
self.in '1s' do
  ScheduledJobs.run(:hello)
end

# Age off
every '1h', first_in: '10m' do
  ScheduledJobs.run(:age_off)
end

# Notebook click summaries
every '1h', first_in: '15s' do
  ScheduledJobs.run(:notebook_summaries)
end

# Notebook suggestions
if Rails.env.production?
  # Run at 4am daily
  cron '0 4 * * * UTC' do
    ScheduledJobs.run(:nightly_computation)
  end
else
  # Run in dev if results are old
  recommendations_old =
    SuggestedNotebook.count.zero? ||
    SuggestedNotebook.pluck(:updated_at).max < 8.hours.ago
  if Notebook.count.nonzero? && recommendations_old
    self.in '30s' do
      ScheduledJobs.run(:nightly_computation)
    end
  end
end
