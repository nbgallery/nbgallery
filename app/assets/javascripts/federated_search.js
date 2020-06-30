function ajaxSearchSuccess(tabElem, response) {
  tabElem.find(".logo-loading").addClass("hidden");
  tabElem.find(".tagline").removeClass("hidden");
  tabElem.find(".tab-pane-content").css("opacity", "1");

  // hacky fix for changing relative URLs to absolute urls
  if (tabElem.attr("id") !== "mainSearch") {
    var baseUrl = $('a[href="#' + tabElem.attr("id") + '"]').attr("data-url");
    html = response.replace(/href="\//gi, 'href="' + baseUrl + "/");
  } else {
    html = response;
  }
  tabElem.find(".result-container").html(html);

  // register all js actions
  tabElem.find('.sortResultsForm').submit(function(e) {
    e.preventDefault();
    url = e.target.action.split("?")[0] + "?" + $(this).serialize();
    ajaxSearch(url, tabElem);
  });
  tabElem.find('.sortDropDown').change(function(){
    tabElem.find('.sortResultsForm').trigger("submit");
  }).val(tabElem.find('.sortHidden').val());

  tabElem.find('.sparkline').sparkline();
  tabElem.find('.minimize').shave(100);
  tabElem.find('.tooltip-right').tooltipster({
    maxWidth:500,
    side:'right'
  });
  tabElem.find('.tooltips, .tooltip-title').tooltipster({
    maxWidth:250
  });

  tabElem.find("a").click(function(e) {
    if ($(this).parents(".pagination").length != 0) {
      // pagination should be ajax
      e.preventDefault();
      ajaxSearch($(this).attr('href'), tabElem);
    } else if (this.origin !== window.location.origin) {
      // open external links in new tab
      e.preventDefault();
      window.open($(this).attr("href"), "_blank");
    }
  });
}

function ajaxSearchError(tabElem, response) {
  tabElem.find(".logo-loading").addClass("hidden");
  tabElem.find(".tagline").addClass("hidden");
  tabElem.find(".tab-pane-content").css("opacity", "1");
  tabElem.find(".result-container").html('<div class="alert alert-danger">There was an error obtaining search results.</div>');
}

function updateHistory(url, tabId) {
  var params = "?" + (url.split("?")[1] ? url.split("?")[1] : "");
  // fix so ajax params dont appear in urls
  params = params.replace("ajax=true", "").replace("?&", "?").replace("&&", "&");
  history.replaceState({ajaxSearch: true} , null, location.pathname + params.split("#")[0] + "#" + tabId);
}

window.addEventListener("popstate", function(e) {
  if (e.state && e.state.ajaxSearch) {
    location.reload();
  }
});

function ajaxSearch(url, tabElem) {
  updateHistory(url, tabElem.attr("id"));

  tabElem.find(".logo-loading").removeClass("hidden");
  tabElem.find(".tab-pane-content").css("opacity", "0.5");
  tabElem.find("select").attr("disabled", "true");

  $.ajax({
    method: 'GET',
    url: url.indexOf("ajax=") === -1 ? url + "&ajax=true" : url,
    success: function(response) {
      ajaxSearchSuccess(tabElem, response);
    },
    error: function(response){
      ajaxSearchError(tabElem, response);
    }
  });
}

$(document).ready(function() {

  // check each external gallery for connectivity
  $(".tab a.gallerySearch.external-gallery").each(function(index, elem) {
    var url = $(elem).attr("data-url");
    $.ajax({
      method: 'GET',
      url: url + '/notebooks.json?q=test_search_return_zero_results',
      error: function(response) {
        $(elem).tooltip({ title: "Error connecting to gallery", placement: "bottom" });
        $(elem).closest("li.tab").addClass("disabled");
        $(elem).click(function(e) {  return false; });
      }
    });
  });

  // paginate search results using ajax
  $("#mainSearch .result-container a").click(function(e) {
    if ($(this).parents(".pagination").length != 0) {
      e.preventDefault();
      var url = $(this).attr('href');
      ajaxSearch(url, $("#mainSearch"));
    }
  });

  // update sorting using ajax
  $("#mainSearch .sortResultsForm").submit(function(e) {
    e.preventDefault();
    url = e.target.action.split("?")[0] + "?" + $(this).serialize();
    ajaxSearch(url, $("#mainSearch"));
  });

  // on search tab show
  $(".tab a.gallerySearch").on("show.bs.tab", function(e) {
    var tabElem = $($(this).attr("href"));

    // are the results already loaded?
    if (tabElem.find(".result-container").is(":empty")
        || tabElem.find(".result-container").children('.alert-danger').length > 0) {

      var baseUrl = $(this).attr("data-url");
      // first click on tab so make sure we load first page
      var params = location.search.replace(/page=[0-9]\d*/gi, "page=1");
      ajaxSearch(baseUrl + "/notebooks" + params, tabElem);
    } else {
      var params = tabElem.find(".sortResultsForm").length > 0 ?
            "?" + tabElem.find(".sortResultsForm").serialize() : location.search;
      updateHistory(location.pathname + params, tabElem.attr("id"));
    }
  });

  // select the correct tab on page load
  if ($('#mainSearch').length) {
    var tabId = location.hash;
    if (tabId) {
      $('a[href="' + tabId + '"]').click();
    }
  }
});
