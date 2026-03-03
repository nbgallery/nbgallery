#!/bin/bash

# This is intended to be used in conjunction with docker-compose.yml,
# so mysql and opensearch server information should match what's used there.
#
# First, build the dev image if necessary:
#   docker build -t nbgallery/dev -f Dockerfile.dev .
#
# Start mysql and opensearch but not the production nbgallery:
#   docker-compose up -d mysql opensearch (dashboards optional)
# 
# Then run this script:
#   ./docker-dev.sh
#
# The dev container should join the same network as mysql and opensearch.
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
GALLERY__OPENSEARCH__HOSTNAME=${GALLERY__OPENSEARCH__HOSTNAME:=opensearch}
GALLERY__OPENSEARCH__PORT=${GALLERY__OPENSEARCH__PORT:=9200}
GALLERY__OPENSEARCH__URL=${GALLERY__OPENSEARCH__URL:=http://opensearch:9200}

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
  -e EMAIL_DEFAULT_URL_OPTIONS=127.0.0.1:3000 \
  -e EMAIL_ADDRESS=nbgallery_developers@dev.com \
  -e EMAIL_SERVER=smtp \
  -e EMAIL_DOMAIN=dev.com \
  -e EMAIL_PORT=8025 \
  -e GALLERY__EMAIL__GENERAL_FROM=nbgallery_developers@dev.com \
  -e GALLERY__EMAIL__EXCEPTIONS_FROM=exceptions@dev.com \
  -e GALLERY__EMAIL__EXCEPTIONS_TO=nbgallery_developers@dev.com \
  -e GALLERY__EXCEPTIONS__EMAIL_FROM=exceptions@dev.com \
  -e GALLERY__EXCEPTIONS__EMAIL_TO=nbgallery_developers@dev.com \
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
  -e GALLERY__OPENSEARCH__HOSTNAME=$GALLERY__OPENSEARCH__HOSTNAME \
  -e GALLERY__OPENSEARCH__PORT=$GALLERY__OPENSEARCH__PORT \
  -e RAILS_SERVE_STATIC_FILES=true \
  --env-file `pwd`/.env \
  "$@" \
  nbgallery/dev
