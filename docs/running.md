# Running the nbgallery application

You can run nbgallery with the built-in `rails server` command or with [Rack](https://rack.github.io/) servers like [Puma](http://puma.io/) or [Passenger](https://www.phusionpassenger.com/).

## Startup sequence

1. Make sure MySQL/MariaDB is up and running.
1. `bundle exec rake db:migrate` must be run whenever there are database schema changes, but it's safe to run it every time.
1. If running in production mode: `bundle exec rake assets:precompile`
1. If running the bundled Solr server: `bundle exec rake sunspot:solr:start` (in development mode, [this happens automatically](../config/initializers/sunspot.rb))
1. Start the app: e.g. `rails server` or via a Rack server like [Puma](http://puma.io/), [Passenger](https://www.phusionpassenger.com/), etc.
1. If you need to run scheduled jobs *outside* the app (e.g. if you're using Passenger), start cronic in daemon mode: `bundle exec script/cronic -d -l <logdir>/cronic.log -P <piddir>/cronic.pid`

## Shutdown sequence

1. If running scheduled jobs outside the app, stop the cronic daemon: `bundle exec script/cronic -k -P <piddir>/cronic.pid`
1. Stop the rails app server
1. If running the bundled Solr server: `bundle exec rake sunspot:solr:stop` (in development mode, [this happens automatically](../config/initializers/sunspot.rb))

