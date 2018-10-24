# Installing nbgallery from source

## Overview

We have successfully installed nbgallery on CentOS, Ubuntu, and Mac Homebrew.  Here's an overview of the OS-level packages you'll need to install first.  Jump down to the platform-specific notes below for more detail.

 * Utilities: git, make, g++
 * Ruby version 2.3, with bundler and pry
   * We do use new features from 2.3, so earlier versions will not work.  We have not tested with 2.4, and we ran into problems with 2.5 on Mac so there are probably some incompatibilities there.
 * Dependencies for various ruby gems: ssdeep, ImageMagick, zlib, xml dev packages
 * MySQL or MariaDB, with dev packages
 * Java - version 8 preferred (see [Solr notes](solr.md))

Once you've installed all the necessary packages:

 * Download or clone the nbgallery source from github
 * `cd` into the nbgallery source directory
 * Run `bundle install` to install all the ruby gems used by nbgallery

## Platform-specfic notes

### CentOS

Ssdeep is in the extra packages repo, so you'll need to `sudo yum install epel-release` to enable those.  Here are other package names to install with yum:

```
git
make
gcc-c++
ruby-devel
rubygem-bundler
ssdeep-devel
ImageMagick-devel
zlib-devel
libxml2-devel
mariadb-server
mariadb-devel
java-1.8.0-openjdk-headless
```

You will probably want to install `pry` for use with the rails console: `gem install pry` (may require sudo)

### Ubuntu

Packages to install with apt:

```
git
make
g++
ruby
ruby-dev
pry
ruby-bundler
zlib1g-dev
libfuzzy-dev
libxml2-dev
libmagick++-dev
mariadb-server
libmariadb-client-lgpl-dev
openjdk-8-jre-headless
```

### Mac Homebrew

These notes are from September 2018.  Please [let us know](https://github.com/nbgallery/nbgallery/issues/new) if you have updates or corrections.

1. Install [homebrew](https://brew.sh/) if you haven't already
1. Install Java, preferably 1.8, for [solr](solr.md).  (You don't need to do this through `brew`.)
1. Install mariadb - [reference](https://mariadb.com/kb/en/library/installing-mariadb-on-macos-using-homebrew/).  Mysql may work too but we haven't tried it.
   1. `brew install mariadb`
   1. `brew services start mariadb` if you want it to run automatically at startup
1. Install ruby **2.3** with rvm
   1. `brew install gnupg`
   1. Follow the directions [here](https://rvm.io/) but you may need the gpg workaround [here](https://rvm.io/rvm/security)
1. Install various dependencies for ruby gems
   1. `brew install git`
   1. `brew install openssl`
   1. `brew install ssdeep`
   1. ImageMagick using [this workaround](https://stackoverflow.com/questions/39494672/rmagick-installation-cant-find-magickwand-h):
      1. `brew unlink imagemagick`
      1. `brew install imagemagick@6 && brew link imagemagick@6 --force`
   
