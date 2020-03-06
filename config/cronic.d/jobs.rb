# Hello world at startup
self.in '1s' do
  ScheduledJobs.run(:hello)
end

# Age off
cron GalleryConfig.cron.age_off do
  ScheduledJobs.run(:age_off)
end

# Notebook daily summaries
cron GalleryConfig.cron.notebook_dailies do
  ScheduledJobs.run(:notebook_dailies)
end

# User click summaries
cron GalleryConfig.cron.user_summaries do
  ScheduledJobs.run(:user_summaries)
end

# Notebook click summaries
cron GalleryConfig.cron.notebook_summaries do
  ScheduledJobs.run(:notebook_summaries)
end

# Subscription email
cron GalleryConfig.cron.daily_subscription_email do
    ScheduledJobs.run(:daily_subscription_email)
end

# Notebook suggestions
if Rails.env.production?
  cron GalleryConfig.cron.nightly_computation do
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
