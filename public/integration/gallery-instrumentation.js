$.ajaxSetup({ xhrFields: { withCredentials: true } });

var get_client_base = function() {
  var pathname = window.location.pathname;
  pages = ['/tree', '/notebooks', '/terminals']
  for (i in pages) {
    index = pathname.indexOf(pages[i]);
    if (index >= 0) {
      return pathname.substr(0, index);
    }
  }
}

require(['base/js/utils', 'services/config', 'base/js/events'], function(utils, configmod, events) {
  var config = new configmod.ConfigSection('common', {base_url: utils.get_body_data("baseUrl")});
  config.load();

  // Post the client name/url to the gallery as an environment
  config.loaded.then(function() {
    var nbgallery = config['data'].nbgallery;
    var base = nbgallery.url;

    require([base + '/integration/md5.js'], function() {

      // Handle execution requests
      events.on('execute.CodeCell', function (evt, data) {
        // Add current time to the cell
        var cell = data.cell;
        cell.start_time = new Date().getTime();
        console.log('execute: ' + cell.toJSON().source.substr(0, 70) + '...');
      });

      // Handle execution completion
      events.on('finished_execute.CodeCell', function (evt, data) {
        var cell = data.cell;

        // Prevent getting called twice for the same execution
        if (cell.start_time == undefined) {
          return;
        }

        // Populate cell execution data
        var log = {};
        log['runtime'] = ((new Date().getTime()) - cell.start_time) / 1000.0;
        cell.start_time = undefined;
        log['md5'] = CryptoJS.MD5(cell.toJSON().source).toString();
        log['success'] = true;
        log['uuid'] = undefined;

        outputs = cell.output_area.outputs;
        for(i in outputs) {
          if(outputs[i].output_type == 'error') {
            log['success'] = false;
          }
        }

        // Post to gallery
        if (Jupyter.notebook.metadata.gallery != undefined) {
          log['uuid'] = Jupyter.notebook.metadata.gallery.link;
          if (log['uuid'] == undefined) {
            log['uuid'] = Jupyter.notebook.metadata.gallery.clone;
          }
        }
        console.log('finished_execute: ' + cell.toJSON().source.substr(0, 70) + '...');
        console.log(log);
        if (log['uuid'] != undefined) {
          $.ajax({
            method: 'POST',
            headers: { Accept: 'application/json' },
            url: base + "/executions",
            data: log,
            xhrFields: { withCredentials: true }
          });
        }
      });
    });

    console.log('gallery-instrumentation loaded');
  });
});
