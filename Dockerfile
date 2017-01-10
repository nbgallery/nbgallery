FROM ruby:2.3

# Install OS packages
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    mysql-client \
    vim \
    libmagickcore-dev && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/nbgallery

# Copy everything needed to bundle install
COPY Gemfile Gemfile.lock ./
COPY extensions extensions/
RUN bundle install --deployment --without=development test

# Copy over the rest
COPY Rakefile config.ru docker-entrypoint.sh ./
COPY bin bin/
COPY config config/
COPY db db/
COPY lib lib/
COPY public public/
COPY script script/
COPY vendor vendor/
COPY app app/

# Final setup for running the app
EXPOSE 3000
ENV RAILS_ENV=production
CMD ["/usr/src/nbgallery/docker-entrypoint.sh"]
