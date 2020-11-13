# Running nbgallery in docker

The nbgallery Rails application is automatically built from the master branch as the [nbgallery/nbgallery image](https://hub.docker.com/r/nbgallery/nbgallery/) at [Docker Hub](https://hub.docker.com).  Thanks to [Justin Fleck](https://github.com/jfleck1), we have a [docker compose configuration](../docker-compose.yml) to run nbgallery, mysql, and solr in separate docker containers mounted on local storage.  We recommend using docker compose if possible.  (If you get a `java.nio.file.AccessDeniedException`, please see [issue 38](https://github.com/nbgallery/nbgallery/issues/38).)

You can also launch a Jupyter instance pre-configured to [integrate with your nbgallery instance](jupyter_integration.md) by loading our additional [compose file](../docker-compose-with-jupyter.yml):

```
mkdir -p docker/data/solr/data #Create data directory for SOLR (others are created automatically)
chown -R 8983:8983 docker/data/solr #Change owner of solr data directory for the container to be able to use it
chown -R 8983:8983 docker/config/solr #Change owner of solr config directory for the container to be able to use it
docker-compose up -d #start the application
#With Jupyter
# docker-compose -f docker-compose.yml -f docker-compose-with-jupyter.yml up -d #start the application
docker-compose down #stop the application
#With Jupyter
# docker-compose -f docker-compose.yml -f docker-compose-with-jupyter.yml down #stop the application
```

If you need a mail server for development, please see the commented out section of the [compose file](../docker-compose.yml) which has a fake smtp server container.

## Manual docker setup - outdated

These notes were written in December 2016 while and need a significant re-write for Solr (and other possible items).  For most recently confviguration settings, look at the docker-compose file.  We welcome [contributions](https://github.com/nbgallery/nbgallery/pulls) in the form of notes, scripts, [docker compose](https://docs.docker.com/compose/) files, etc!

#### Mysql container

Use the [official image](https://hub.docker.com/_/mysql/).

`docker run --rm --name mysql -e MYSQL_ROOT_PASSWORD=xyz -p 3306:3306 mysql`

TODO: you may want to run this such that the mysql storage is mounted from a local directory.

#### Solr container

Use the [official image](https://hub.docker.com/_/solr/).

You will need to create a solr core called `default` with an appropriate `schema.xml` config file.  The config bundled with the `sunspot_solr` gem works.  The solr image has an entrypoint that will create the core at startup:

```
docker run --rm --name solr -P -v `bundle show sunspot_solr`/solr/solr/configsets/sunspot/conf:/myconfig solr solr-create -c default -d /myconfig
```

You should see some output like this:

```
Creating core with: -c default -d /myconfig

Copying configuration to new core instance directory:
/opt/solr/server/solr/default

Creating new core 'default' using command:
http://localhost:8983/solr/admin/cores?action=CREATE&name=default&instanceDir=default
```

Alternately, you can use `docker exec` to create the solr core -- see the [docker hub page](https://hub.docker.com/_/solr/) for examples.

TODO: you may want to run this such that the solr storage is mounted from a local directory.  However, it's fairly quick to reindex the notebooks, so that isn't strictly necessary.

#### nbgallery container

Use the [nbgallery image](https://hub.docker.com/r/nbgallery/nbgallery/).  At startup, the entrypoint script will create the database and run migrations (if necessary), pre-compile static assets, and launch the rails server.

The [docker-run.sh](docker-run.sh) script will run the image with a bunch of environment variables set to make it work.  You'll need to set a few of them yourself, though:

 * IPs of the mysql and solr containers from `docker network inspect bridge`
 * Mysql root password should match what you used to run the mysql container (you could also run the mysql container without a root password)
 * EMAIL_ADDRESS - The value that shows up in the 'from' field for e-mail confirmation
 * EMAIL_USERNAME - The username used to authenticate to your SMTP server
 * EMAIL_PASSWORD - The passwword used to authenticate to your SMTP server
 * EMAIL_DOMAIN - The actual domain for your server (such as nb.gallery)
 * EMAIL_SERVER - The SMTP server (may not be the same as EMAIL_DOMAIN, such as if you are running in AWS)
 * EMAIL_PORT - Port the SMTP server is listening on (default is 587)
 * EMAIL_DEFAULT_URL_OPTIONS_HOST - Often the same value as EMAIL_DOMAIN
 * GITHUB_ID - Optional. This is the OAuth ID for Github authentication
 * GITHUB_SECRET - Optional. This is the OAuth secret for Github authentication
 * GITLAB_ID - Optional. OAuth ID for Gitlab authentication
 * GITLAB_SECRET - Optional. OAuth secret for Gitlab authentication
 * GITLAB_URL - Optional. URL for Gitlab server (ex http://gitlab.com/api/v4) for Gitlab authentication
 * FACEBOOK_ID - Optional. This is the OAuth ID for Facebook authentication
 * FACEBOOK_SECRET - Optional. This is the OAuth secret for Facebook authentication
 * GOOGLE_ID - Optional. This is the OAuth ID for Google authentication
 * GOOGLE_SECRET - Optional. This is the OAuth secret for Google authentication
 * SECRET_KEY_BASE - `rake secret` will generate one

The [docker-run.sh](docker-run.sh) script will also mount a local directory for logs and data (notebooks, etc) so those will persist outside the container.
