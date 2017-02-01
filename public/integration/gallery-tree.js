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

require(['base/js/utils', 'services/config'], function(utils, configmod) {
  var config = new configmod.ConfigSection('common', {base_url: utils.get_body_data("baseUrl")});
  config.load();

  // Post the client name/url to the gallery as an environment
  config.loaded.then(function() {
    var nbgallery = config['data'].nbgallery;
    var base = nbgallery.url;
    var client_url = window.location.origin + get_client_base();

    if (nbgallery.client == undefined || nbgallery.client.name == undefined) {
      config.update({ nbgallery: { client: { name: 'nbgallery-client' } } });
    }

    if (nbgallery.client == undefined || nbgallery.client.url != client_url) {
      $.ajax({
        method: 'POST',
        headers: { Accept: 'application/json' },
        url: base + '/environments',
        data: {
          name: nbgallery.client.name,
          url: client_url
        },
        success: function() {
          console.log("Set environment " + nbgallery.client.name + ": " + client_url);
          config.update({ nbgallery: { client: { url: client_url } } });
        },
        xhrFields: { withCredentials: true }
      });
    }
    console.log('gallery-tree loaded');
  });
});
