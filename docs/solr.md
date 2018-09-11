# nbgallery and Solr 

The nbgallery application requires an [Apache Solr](http://lucene.apache.org/solr/) server for full-text indexing.  For small to medium instances (small thousands of notebooks and users), the bundled [sunspot](https://github.com/sunspot/sunspot) Solr server may suffice.  Larger instances may require a standalone server.

These notes were written in late 2016, so may be out of date.  [Please submit updates and corrections](https://github.com/nbgallery/nbgallery/issues/new).

We haven't explored running Solr as an standalone server.  We are using the sunspot_solr gem, which wraps Solr in Ruby with some convenient rake tasks.  These notes apply to running Solr with that gem, so they may or may not apply to a standalone installation.  For standalone installations, these security references may be useful: [ref one](https://cwiki.apache.org/confluence/display/solr/Securing+Solr), [ref two](https://wiki.apache.org/solr/SolrSecurity).

From our experience, Java 8 is preferred, but Java 7 might work too.  Java 6 is too old.  Java 9 is too new -- the solr script uses JVM options that no longer exist, but you might be able to patch it.

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
