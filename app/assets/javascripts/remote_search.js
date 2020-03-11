/*
  Other galleries can include this JS file to allow federated search
  without having to deal with CORS.
*/
function getGallerySearch() {
  return function search(url, successCallback, errorCallback) {
    // ensure we can only call the notebook search endpoint
    var tmpElem = document.createElement("a");
    tmpElem.href = url;
    if (!tmpElem.pathname.startsWith("/notebooks/search"))  {
      errorCallback("Remote search to incorrect URL");
    }
    $.ajax({
      method: 'GET',
      url: url,
      success: function(response) {
        successCallback(response)
      },
      error: function(response){
        errorCallback(response);
      }
    });
  }
}
