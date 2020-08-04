# What is nbgallery?

nbgallery (notebook gallery) is an enterprise [Jupyter](http://jupyter.org/) notebook sharing and collaboration platform.  For an overview, please check out our [github.io site](https://nbgallery.github.io/).

![nbgallery screenshot](https://user-images.githubusercontent.com/51969207/73755334-e212ab80-4733-11ea-96ef-288e097fd588.png)

[Tony Hirst](https://github.com/psychemedia) published a nice walkthrough of some of the features of nbgallery [on his blog](https://blog.ouseful.info/2019/01/28/first-play-with-nbgallery/).

## Getting Started

### Requirements

nbgallery is a [Ruby on Rails](https://rubyonrails.org/) application.  You can run it with the built-in `rails server` command or with [Rack](https://rack.github.io/) servers like [Puma](http://puma.io/) or [Passenger](https://www.phusionpassenger.com/).

The nbgallery application requires a MySQL or MariaDB server.  Other SQL-based servers may work but have not been tested.  We recommend creating a separate mysql user account for use by the app.

The application also requires an [Apache Solr](http://lucene.apache.org/solr/) server for full-text indexing.  For small to medium instances (small thousands of notebooks and users), the bundled [sunspot](https://github.com/sunspot/sunspot) Solr server may suffice.  Larger instances may require a standalone server.  See our [notes](docs/solr.md) for more detail.

### Installation

You can install nbgallery on various platforms:

 * [Install from source on Linux or Mac Homebrew](docs/installation.md)
 * [Run with docker](docs/docker.md)

### Configuration

Most configuration settings will should work out of the box, but there are a few things you'll need to set up.  See our [configuration notes](docs/configuration.md) for more detail.

### Running the server

Once everything is configured, you're ready to go!  See [this page](docs/running.md) for details on starting up the app and shutting it down.

## Jupyter integration

One of the benefits of nbgallery is its two-way integration with Jupyter. You can launch notebooks from nbgallery into Jupyter with a single click. Within Jupyter, the Gallery menu enables you to save notebooks to nbgallery and submit change requests to other notebook authors.  See [this page](docs/jupyter_integration.md) for more information.

## Providing OAuth to JupyterHub 

If you want to use NBGallery as your central login repository for your JupyterHub, you can configure NBGallery to operate as an OAuth2 provider.  This will work for other applications as well, but for a detailed write-up of how it can be connected to JupyterHub, see [this page](docs/jupyter_hub_oauth.md).

## Selected topics

Here is some documentation on various features of nbgallery:

 * Our [notebook recommender system](https://nbgallery.github.io/recommendation.html) helps users find notebooks that are most relevant to them.
 * When [integrated with Jupyter](docs/jupyter_integration.md), nbgallery can track cell executions to assess whether [notebooks are healthy](https://nbgallery.github.io/health_paper.html).
 * Our [notebook review system](docs/notebook_review.md) helps build quality and user confidence through peer review of notebooks.
 * The [extension system](docs/extensions.md) enables you to add custom/proprietary features that are specific to your enterprise.
 * Notebook revisions can be [tracked in git](docs/revisions.md).
 * [Notes on computation and cleanup jobs](docs/scheduled_jobs.md).
 * [Notes on backing up nbgallery](docs/backup.md).

## Contributions

Issues and pull requests are welcome.  For code contributions, please note that we use [rubocop](https://github.com/bbatsov/rubocop) ([our config](.rubocop.yml)), so please run `overcommit --install` in your project directory to activate the git commit hooks.
