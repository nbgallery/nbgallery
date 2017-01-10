#!/bin/sh

mysql -h$GALLERY__MYSQL__HOST -p$GALLERY__MYSQL__PORT -u$GALLERY__MYSQL__USERNAME -p"$GALLERY__MYSQL__PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $GALLERY__MYSQL__DATABASE"
bundle exec rake db:migrate
bundle exec rake assets:precompile
rails server -b 0.0.0.0
