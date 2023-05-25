#!/bin/bash

# This is intended to be used in conjunction with docker-compose.yml,
# so mysql and solr server information should match what's used there.
#
# First, build the dev image if necessary:
#   docker build -t nbgallery/dev -f Dockerfile.dev .
#
# Start mysql and solr but not the production nbgallery:
#   docker-compose up -d mysql solr
# 
# Then run this script:
#   ./docker-dev.sh
#
# The dev container should join the same network as mysql and solr.
# Once inside the container, bundler is configured to install gems
# into a mounted directory, so they will persist if you restart the
# contaier.  Use bundler to install gems if the Gemfile has changed
# or if this is the first time you've used the dev container:
#   bundle install
#
# Run the rails server on port 3000:
#   bundle exec rails server -b 0.0.0.0

GALLERY__MYSQL__HOST=${GALLERY__MYSQL__HOST:=mysql}
GALLERY__MYSQL__PORT=${GALLERY__MYSQL__PORT:=3306}
GALLERY__MYSQL__USERNAME=${GALLERY__MYSQL__USERNAME:=root}
GALLERY__MYSQL__PASSWORD=${GALLERY__MYSQL__PASSWORD:=xyz}
GALLERY__MYSQL__DATABASE=${GALLERY__MYSQL__DATABASE:=gallery}
GALLERY__SOLR__HOSTNAME=${GALLERY__SOLR__HOSTNAME:=solr}
GALLERY__SOLR__PORT=${GALLERY__SOLR__PORT:=8983}

docker run \
  --rm \
  -it \
  --name nbgallery_dev \
  --network nbgallery_default \
  -p 3000:3000 \
  -v `pwd`:/usr/src/nbgallery \
  -v `pwd`/docker/log:/usr/src/nbgallery/log \
  -v `pwd`/docker/data:/usr/src/nbgallery/data \
  -v `pwd`/docker/bundle:/usr/src/nbgallery/bundle \
  -e GALLERY__DIRECTORIES__DATA=/usr/src/nbgallery/data \
  -e GALLERY__DIRECTORIES__CACHE=/usr/src/nbgallery/data/cache \
  -e GALLERY__DIRECTORIES__CHANGE_REQUESTS=/usr/src/nbgallery/data/change_requests \
  -e GALLERY__DIRECTORIES__STAGING=/usr/src/nbgallery/data/staging \
  -e BUNDLE_PATH=/usr/src/nbgallery/bundle \
  -e GALLERY__MYSQL__HOST=$GALLERY__MYSQL__HOST \
  -e GALLERY__MYSQL__PORT=$GALLERY__MYSQL__PORT \
  -e GALLERY__MYSQL__USERNAME=$GALLERY__MYSQL__USERNAME \
  -e GALLERY__MYSQL__PASSWORD=$GALLERY__MYSQL__PASSWORD \
  -e GALLERY__MYSQL__DATABASE=$GALLERY__MYSQL__DATABASE \
  -e GALLERY__SOLR__HOSTNAME=$GALLERY__SOLR__HOSTNAME \
  -e GALLERY__SOLR__PORT=$GALLERY__SOLR__PORT \
  -e RAILS_SERVE_STATIC_FILES=true \
  -e RUN_SOLR=false \
  --env-file `pwd`/.env \
  "$@" \
  nbgallery/dev
