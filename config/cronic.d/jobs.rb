# Hello world at startup
self.in '1s' do
  ScheduledJobs.run(:hello)
end

# Age off
every '1h', first_in: '10m' do
  ScheduledJobs.run(:age_off)
end

# Notebook click summaries
# Run at 0100am daily
cron '0 1 * * * UTC' do
  ScheduledJobs.run(:notebook_summaries)
end

# Notebook daily summaries
# Run at 1230am daily
cron '30 0 * * * UTC' do
  ScheduledJobs.run(:notebook_dailies)
end

# User click summaries
# Run at 1235am daily
cron '35 0 * * * UTC' do
  ScheduledJobs.run(:user_summaries)
end

# Notebook suggestions
if Rails.env.production?
  # Run at 4am daily
  cron '0 4 * * * UTC' do
    ScheduledJobs.run(:nightly_computation)
  end
else
  # Run in dev if results are old
  latest_recommendation = SuggestedNotebook.maximum(:updated_at) || Time.current
  latest_notebook = Notebook.maximum(:updated_at) || Time.current
  recommendations_old = SuggestedNotebook.count.zero? || latest_recommendation < latest_notebook
  if Notebook.count.nonzero? && recommendations_old
    self.in '5m' do
      ScheduledJobs.run(:nightly_computation)
    end
  end
end
