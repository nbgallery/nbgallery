# Integrating Jupyter with nbgallery

## Overview

One of the benefits of nbgallery is its two-way integration with Jupyter.  You can launch notebooks from nbgallery into Jupyter with a single click.  Within Jupyter, the Gallery menu enables you to save notebooks to nbgallery and submit change requests to other notebook authors.

If you're using our [docker image](https://hub.docker.com/r/nbgallery/jupyter-alpine/) to run Jupyter, it's already configured to integrate with nbgallery.  When you launch the docker container, just set the environment variable `NBGALLERY_URL` to the location of your nbgallery instance.  When you visit the Jupyter `/tree` page, it will register a Jupyter "environment" with nbgallery.  When you click the `Run in Jupyter` button in nbgallery, it will launch the notebook into that Jupyter environment.  If you have more than one Jupyter environment configured, you can set one as default or have nbgallery prompt you when you click `Run in Jupyter`.

You can launch a full suite of nbgallery/mysql/solr plus an integrated Jupyter instance using our docker compose files:

```
docker-compose -f docker-compose.yml -f docker-compose-with-jupyter.yml up
```

## Technical details

Both directions of the integration are implemented with [cross-domain](https://en.wikipedia.org/wiki/Cross-origin_resource_sharing) [Ajax](https://en.wikipedia.org/wiki/Ajax_(programming)).  This means that notebooks are bounced through the browser -- nbgallery does not communicate directly with Jupyter or vice versa.  For example, when you click `Run in Jupyter`, we use Ajax to download the notebook from nbgallery and then upload it into Jupyter.  To enable cross-domain requests, nbgallery's CORS configuration (see [application.rb](../config/application.rb)) allows requests to a necessary subset of API endpoints from any origin (because you can have multiple Jupyter instances at arbitrary locations).  On the other side, Jupyter's CORS configuration limits the origin to the `NBGALLERY_URL`.

## Optional integration scripts

Our [jupyter_nbgallery extension](https://github.com/nbgallery/nbgallery-extensions) can optionally download additional integration javascripts from nbgallery.  This can be configured in the `nbgallery` section of Jupyter's `nbconfig/common.json` ([here's a stub](https://github.com/nbgallery/jupyter-alpine/blob/master/config/jupyter/nbconfig/common.json)).  There are two optional javascripts in the nbgallery codebase:

 * [**Notebook instrumentation**](../public/integration/gallery-instrumentation.js): This enables logging of cell executions back to nbgallery.  This is required for our [notebook health evaluation](https://nbgallery.github.io/health_paper.html), which feeds into our [notebook recommender](https://nbgallery.github.io/recommendation.html) when enabled.  To enable instrumentation:
   * If using our docker image: Set `-e NBGALLERY_ENABLE_INSTRUMENTATION=1` on the `docker run` command line
   * Manual configuration: Add `"gallery-instrumentation.js"` to the `nbgallery.extra_integration.notebook` list in `nbconfig/common.json`.  
 
 * [**Automatic downloads at startup**](../public/integration/gallery-autodownload.js): This will automatically download your recently executed and starred notebooks into folders when you first visit the Jupyter `/tree` page.  This is useful to restore your favorite notebooks if your Jupyter environment is not persistent.  Note that instrumentation must also be enabled to auto-download recently executed notebooks.  To enable auto-download:
   * If using our docker image: Set `-e NBGALLERY_ENABLE_AUTODOWNLOAD=1` on the `docker run` command line
   * Manual configuration: Add `"gallery-autodownload.js"` to the `nbgallery.extra_integration.tree` list in `nbconfig/common.json` to 

You can add custom javascripts to your nbgallery instance through our extension system.

## Manual configuration

If you're not using our docker image for Jupyter, you can still configure Jupyter to integrate with nbgallery:

 * Install our [jupyter_nbgallery extension](https://github.com/nbgallery/nbgallery-extensions).  This contains a server extension for uploading notebooks and a UI extension to add the Gallery menu.
 * Set the following [configuration settings](https://jupyter-notebook.readthedocs.io/en/stable/config.html) in `jupyter_notebook_config.py` ([here's ours](https://github.com/nbgallery/jupyter-alpine/blob/master/config/jupyter/jupyter_notebook_config.py)) or on the command line:
   * `JupyterApp.allow_origin = <URL of your nbgallery instance>`
   * `JupyterApp.allow_credentials = True`
   * `JupyterApp.disable_check_xsrf = True` (note this reduces the security of Jupyter but is necessary for the `Run in Jupyter` button to work)
 * Add an nbgallery section to Jupyter's `nbconfig/common.json`, usually found in `~/.jupyter/nbconfig` ([here's ours](https://github.com/nbgallery/jupyter-alpine/blob/master/config/jupyter/nbconfig/common.json)).  At a minimum, you need to set the URL of your nbgallery instance.  You can also set the client name here; that will show up as the environment name in nbgallery.  Any desired integration scripts (described above) should be enabled here as well.

We believe this is possible with JupyterHub as well, but we haven't tried it ourselves.  If you've tried it, please [let us know how it went](https://github.com/nbgallery/nbgallery/issues/new).

