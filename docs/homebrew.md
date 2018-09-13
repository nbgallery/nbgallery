# Installing nbgallery dependencies on Mac with Homebrew

These notes are from September 2018.  Please [let us know](https://github.com/nbgallery/nbgallery/issues/new) if you have updates or corrections.

1. Install [homebrew](https://brew.sh/) if you haven't already
1. Install Java, preferably 1.8, for [solr](https://github.com/nbgallery/nbgallery/blob/master/docs/solr.md).  (You don't need to do this through `brew`.)
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
      
At this point you should be able to download or clone the code and then run `bundle install`.
