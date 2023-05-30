FROM ruby:2.7
MAINTAINER team@nb.gallery

# Install OS packages
RUN \
  apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    default-mysql-client \
    vim \
    libfuzzy-dev && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/nbgallery

# Copy everything needed to bundle install

COPY Gemfile Gemfile.lock ./
COPY extensions extensions/

RUN \
  bundle config set deployment 'true' && \
  bundle install --jobs 4 --without=development test && \
  rm /usr/src/nbgallery/vendor/bundle/ruby/*/cache/* && \
  rm -rf /usr/src/nbgallery/vendor/bundle/ruby/*/gems/*/test

# Copy over the rest
COPY Rakefile config.ru docker-entrypoint.sh ./
COPY bin bin/
COPY config config/
COPY db db/
COPY lib lib/
COPY public public/
COPY script script/
COPY vendor/assets vendor/assets/
COPY app app/

# # Final setup for running the app
EXPOSE 3000
ENV RAILS_ENV=production
# Required for mathjax to make it out of the container now
ENV RAILS_SERVE_STATIC_FILES=true
CMD ["/usr/src/nbgallery/docker-entrypoint.sh"]
LABEL gallery.nb.version=0.1.0 \
      gallery.nb.description="nbgallery rails app for notebook sharing" \
      gallery.nb.URL="https://github.com/nbgallery"
