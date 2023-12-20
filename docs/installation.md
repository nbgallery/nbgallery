# Installing nbgallery from source

## Overview

NOTE: This is just provded for reference.  The [development container setup](docs/docker.md) should be used as this is not officially supported anymore.  Solr is only supported in the container version anyway so you would need docker anyway.  Only Ubuntu is listed as that was the only environment readily available to update the documentation.

## Ubuntu
```
apt-get install autoconf patch build-essential rustc libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libgmp-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev git libfuzzy-dev mariadb-server libmariadbd-dev  -y
rbenv and remaining setup
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
source ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
git clone https://github.com/nbgallery/nbgallery.git
cd nbgallery
rbenv install 3.1.4 #as of writing 3.1.4 is the latest 3.1 release
rbenv local 3.1.4
gem install bundler
bundle install
```
Once you have gone through the [configuration](configuration.md) you can run `bundle exec rails server -b 0.0.0.0` to start the server.
