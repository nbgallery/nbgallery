# Scheduled Jobs

nbgallery has a number of computational and cleanup tasks that should run on a periodic basis.  We use [cronic](https://github.com/jkraemer/cronic) and [rufus scheduler](https://github.com/jmettraux/rufus-scheduler) to execute the scheduled jobs.  See the [rufus documentation](https://github.com/jmettraux/rufus-scheduler#faq) to consider how your Rack server will interact with it.  For example, with `rails server` the jobs can run within the app, but with Passenger they should be run in a separate cronic process (see notes below).

## Jobs that need to run

The main jobs are defined in [scheduled_jobs.rb](../lib/scheduled_jobs.rb), and the default schedule is defined in [cronic.d/jobs.rb](../config/cronic.d/jobs.rb).  Note that [we do not provide a backup job](backup.md), but additional jobs can be defined by extensions ([example](../samples/backup)).

 * hello: This just logs "Hello, World!" but is sometimes handy to run at startup.
 * age_off: Cleans up orphaned uploads and old change requests that have been resolved.
 * notebook_dailies: Daily usage summary for each notebook, which feeds into trendiness.  This should be run shortly after midnight every day.
 * notebook_summaries: Notebook-centric summary of clicks.  This "caches" some of the click counts you see in the UI, so it should be run as often as you can, depending on how much you care about those numbers being exactly accurate.
 * user_summaries: User-centric summary of clicks.  This computes the author and user contribution scores.
 * nightly_computation: The math for the [recommendation engine](https://nbgallery.github.io/recommendation.html).  We've primarily optimized for memory consumption, but have tried to strike a balance between that, runtime, and database load.  This should be run daily during off-peak hours.
   * similarity_scores: notebook-notebook and user-user similarity scores.
   * recommendations: find notebooks, groups, tags that are most relevant to each user.
   * reviews: computations for the [notebook peer review system](notebook_review.md).

## How to run jobs

By default, the app will run an internal scheduler thread using the [default schedule](../config/cronic.d/jobs.rb).  Depending on what Rack server you use, this may be bad.  For example, the way Passenger spins up extra processes/threads and shuts them down can lead to the scheduler thread dying and not restarting.  For that type of environment, you can use the [cronic script](../script/cronic) to run the jobs in a separate process outside the app.  See the [startup/shutdown notes](running.md) for example commands.

If you don't like the default schedule, or if you'd prefer to use standard `cron`, you can disable the internal scheduler thread by setting `scheduler.internal = false` in [settings.yml](../config/settings.yml).  You can then use the [run_job script](../script/run_job.rb) to run individual jobs at your desired schedule.  Call the script with `bundle` and `rails runner`, and give it a job name:

```
bundle exec rails runner script/run_job.rb age_off
```

Alternatively, you may also configure the cron schedules by changing the cron values in [settings.yml](../config/settings.yml).
