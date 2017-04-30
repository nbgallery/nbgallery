# nbgallery

nbgallery is an enterprise Jupyter notebook sharing and collaboration platform. 

![nbgallery screenshot](https://cloud.githubusercontent.com/assets/8132519/23445445/9f48c65e-fdf8-11e6-8ef0-d9cb7942b870.png)


## Notes

### Startup sequence

1. `bundle exec rake db:migrate`
2. `bundle exec rake assets:precompile`
3. If running Solr locally: `bundle exec rake sunspot:solr:start`
4. Start the app e.g. `rails server`
5. If running crons outside the app (e.g. Passenger): `bundle exec script/cronic -d -l <logdir>/cronic.log -P <piddir>/cronic.pid`

### Shutdown sequence

1. If running crons outside the app: `bundle exec script/cronic -k -P <piddir>/cronic.pid`
2. Stop the app
3. If running Solr locally: `bundle exec rake sunspot:solr:stop`

### Solr

We haven't explored running Solr as an independent server (with the exception of running the solr docker container -- see notes below).  We are using the sunspot_solr gem, which wraps Solr in Ruby with some convenient rake tasks.  These notes apply to running Solr with that gem, so they may or may not apply to a standalone installation.  For standalone installations, it looks like they have some new-ish security features: [ref one](https://cwiki.apache.org/confluence/display/solr/Securing+Solr), [ref two](https://wiki.apache.org/solr/SolrSecurity).

From our experience, Java 8 is preferred, but Java 7 might work too.  Java 6 is too old.  Java 9 is too new -- the solr script uses JVM options that no longer exist -- might be patchable.

You may want/need to bind Solr to an internal/loopback IP for security.  Some hacks are necessary:

 * To bind the server to the IP, add `-Djetty.host=<IP>` to SOLR_OPTS environment variable.  [Setting SOLR_HOST is not sufficient](http://shal.in/post/127561227271/how-to-make-apache-solr-listen-on-a-specific-ip).  This is not ideal because it relies on an implementation detail of Solr (that it runs on top of Jetty) -- I had a reference about this but can't find it now.
 * The above causes the "stop port" to bind to that IP also, but the stop task will then fail because it doesn't use that IP to connect for sending the stop signal.  Here's how we fixed that:
   * Set `STOP_HOST=<IP>` environment variable
   * Add `-DSTOP.HOST=<IP>` to the SOLR_OPTS variable
   * Patch `<sunspot_solr gem dir>/solr/bin/solr` to add `STOP.HOST=$STOP_HOST` (around line 476 in sunspot_solr-2.2.7).  Use `bundle show sunspot_solr` to find this directory.  This is obviously not ideal since bundle may overwrite that directory during a gem upgrade.  The lines should look like this:
```sh
   echo -e "Sending stop command to Solr running on port $SOLR_PORT ... waiting 5 seconds to allow Jetty process $SOLR_PID to stop gracefully."
  "$JAVA" $SOLR_SSL_OPTS $AUTHC_OPTS -jar "$DIR/start.jar" "STOP.HOST=$STOP_HOST" "STOP.PORT=$STOP_PORT" "STOP.KEY=$STOP_KEY" --stop || true
```

### Running in docker

Notes on running mysql, solr, and nbgallery in separate containers.

#### Mysql container

Use the [official image](https://hub.docker.com/_/mysql/).

`docker run --rm --name mysql -e MYSQL_ROOT_PASSWORD=xyz -p 3306:3306 mysql`

TODO: you may want to run this such that the mysql storage is mounted from a local directory

#### Solr container

Use the [official image](https://hub.docker.com/_/solr/).

We need to create a solr core called `default` with an appropriate `schema.xml` config file.  The config bundled with the `sunspot_solr` gem works.  The solr image has an entrypoint that will create the core at startup:

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

TODO: you may want to run this such that the solr storage is mounted from a local directory

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
 * EMAIL_DEFAULT_URL_OPTIONS_HOST - Often the same value as EMAIL_DOMAIN
 * GITHUB_ID - Optional. This is the OAuth ID for Github authentication
 * GITHUB_SECRET - Optional. This is the OAuth secret for Github authentication
 * FACEBOOK_ID - Optional. This is the OAuth ID for Facebook authentication
 * FACEBOOK_SECRET - Optional. This is the OAuth secret for Facebook authentication
 * GOOGLE_ID - Optional. This is the OAuth ID for Google authentication
 * GOOGLE_SECRET - Optional. This is the OAuth secret for Google authentication
 * SECRET_KEY_BASE - `rake secret` will generate one

The [docker-run.sh](docker-run.sh) script will also mount a local directory for logs and data (notebooks, etc) so those will persist outside the container.

