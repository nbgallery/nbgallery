# nbgallery

nbgallery (notebook gallery) is an enterprise [Jupyter](http://jupyter.org/) notebook sharing and collaboration platform.  For an overview, please check out our [github.io site](https://nbgallery.github.io/).

![nbgallery screenshot](https://cloud.githubusercontent.com/assets/8132519/23445445/9f48c65e-fdf8-11e6-8ef0-d9cb7942b870.png)

## Installation

### Requirements

nbgallery is a [Ruby on Rails](https://rubyonrails.org/) application.  You can run it with the built-in `rails server` command or with [Rack](https://rack.github.io/) servers like [Puma](http://puma.io/) or [Passenger](https://www.phusionpassenger.com/).

The nbgallery application requires a MySQL or MariaDB server.  Other SQL-based servers may work but have not been tested.  We recommend creating a separate mysql user account for use by the app.

The application also requires an [Apache Solr](http://lucene.apache.org/solr/) server for full-text indexing.  For small to medium instances (small thousands of notebooks and users), the bundled [sunspot](https://github.com/sunspot/sunspot) Solr server may suffice.  Larger instances may require a standalone server.  See our [notes](https://github.com/nbgallery/nbgallery/blob/master/docs/solr.md) for more detail.

### Installation

You can run nbgallery on various platforms:

 * [Install from source on Linux or Mac Homebrew](https://github.com/nbgallery/nbgallery/blob/master/docs/installation.md)
 * [Run with docker](https://github.com/nbgallery/nbgallery/blob/master/docs/docker.md)
  
### Configuration

General configuration is stored in `config/settings.yml` and `config/settings/#{environment}.yml`.  Precedence of these files is defined by the [config gem](https://github.com/railsconfig/config#accessing-the-settings-object).  These files are under version control, so we recommend creating `config/settings.local.yml` and/or `config/settings/#{environment}.local.yml`, especially if you plan to contribute to the project.  At a minimum, you'll need to configure the mysql section to match your database server, but most other settings should work out of the box.

The app uses [rufus scheduler](https://github.com/jmettraux/rufus-scheduler) to execute periodic scheduled jobs.  See the rufus documentation to consider how your Rack server will interact with it.  For example, with `rails server` the jobs can run within the app, but with Passenger they should be run in a separate process.

### Startup sequence

1. `bundle exec rake db:migrate` must be run whenever there are database schema changes, but it's safe to run it every time.
2. If running in production mode: `bundle exec rake assets:precompile`
3. If running the bundled Solr server: `bundle exec rake sunspot:solr:start`
4. Start the app: e.g. `rails server` or via something like puma, passenger, etc.
5. If running crons outside the app (e.g. Passenger): `bundle exec script/cronic -d -l <logdir>/cronic.log -P <piddir>/cronic.pid`

### Shutdown sequence

1. If running crons outside the app: `bundle exec script/cronic -k -P <piddir>/cronic.pid`
2. Stop the app
3. If running the bundled Solr server: `bundle exec rake sunspot:solr:stop`



## Extension system

The code has an [extension system](extensions) that enables you to add custom/proprietary modules that may be specific to your enterprise environment.  For example, nbgallery has a basic group management system for sharing notebooks, but if your environment has some other mechanism, you can implement a custom [GroupService](lib/extension_points/group_service.rb) as an extension.

## Contributions

Issues and pull requests are welcome.  For code contributions, please note that we use [rubocop](https://github.com/bbatsov/rubocop) ([our config](.rubocop.yml)), so please run `overcommit --install` in your project directory to activate the git commit hooks.
