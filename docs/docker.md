# Running nbgallery in docker

The nbgallery Rails application is automatically built from the `main` branch as the [nbgallery/nbgallery image](https://hub.docker.com/r/nbgallery/nbgallery/) at [Docker Hub](https://hub.docker.com).  We recommend using `docker-compose` to run nbgallery, MySQL, and Apache Solr in separate docker containers mounted on local storage.  We use the official MySQL image, but Solr must be configured to work with the [Ruby Sunspot gem](https://github.com/sunspot/sunspot), so we recommend using our pre-configured [Solr image](https://github.com/nbgallery/nbgallery-solr).

## Docker quick start

 1. Create directories and change ownership for the Solr container to use:
 
    ```
    mkdir -p docker/data/solr docker/config/solr
    chown -R 8983:8983 docker/data/solr docker/config/solr
    ```
 
 2. *Optional:* Set the environment variable `$SECRET_KEY_BASE` for Rails to use.  The nbgallery container will generate a value at startup if necessary, but you may want to configure it outside the container if you anticipate using `docker exec` to administer the server.  The following command will generate a random value you can use, although any long random string will do:
 
     ```
     docker run --rm nbgallery/nbgallery ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
     ```

 3. *Optional:* Set environment variables `$NBGALLERY_ADMIN_USER`, `$NBGALLERY_ADMIN_PASSWORD`, and `$NBGALLERY_ADMIN_EMAIL` to automatically create an admin user at startup.  The password must be at least 6 characters and the email must be well-formed (`username@domain.tld`).  See [Configuration](configuration.md) for other ways to create an initial user and for environment variables you may want to set.

 4. Start the application.  The server will perform database migrations and asset compilation at startup, so it make take a couple minutes before it will respond to requests.  Note that this may not work under `sudo` since `$PWD` may not be set.

     ```
     docker-compose up -d
     ```

     Optionally, you can load an [additional compose file](../docker-compose-with-jupyter.yml) to launch our [Jupyter image](https://github.com/nbgallery/docker-images/tree/main/base-notebook) pre-configured to [integrate with the nbgallery server](jupyter_integration.md):

     ```
     docker-compose -f docker-compose.yml -f docker-compose-with-jupyter.yml up -d 
     ```

 5. Stop the application:

     ```
     docker-compose down
     ```

     Or, if using the additional Jupyter container:

     ```
     docker-compose -f docker-compose.yml -f docker-compose-with-jupyter.yml down
     ```

## nbgallery development in docker

The [Dockerfile.dev](../Dockerfile.dev) recipe can be used to build an `nbgallery/dev` container with Ruby 2.3 and Linux dependencies needed for command-line nbgallery development:

```
docker build -t nbgallery/dev -f Dockerfile.dev .
```

You can then use the regular docker-compose file to start up just MySQL and Solr:

```
docker-compose up -d mysql solr
```

Then, run the [dev startup script](../docker-dev.sh) to start the `nbgallery/dev` container:

```
./docker-dev.sh
```

The dev startup script should attach the container to the same network as MySQL and Solr.  Ruby Bundler is configured to install gems into a mounted directory, so they will persist if you restart the container.  You will need to use bundler to install gems whenever the Gemfile.lock changes or if this is the first time you've used the dev container:

```
bundle install
```

Then to run the rails server:

```
bundle exec rails server -b 0.0.0.0
```

If you need a mail server for development, please see the commented out section of the [compose file](../docker-compose.yml), which will set up a fake SMTP server container.
