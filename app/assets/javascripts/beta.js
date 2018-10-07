document.addEventListener("turbolinks:load", function(){

  $(document).ready(function(){
    var selector = '.tabs a'
  
    $(selector).on('click', function(){
      $(selector).removeClass('active');
      $(this).addClass('active');
    });
  });

  $('a.switchGUI').on("click", function(e) {
    e.preventDefault();
    window.location = '/';
  });
 
  $('#newHomePageNotebooks').load('/beta_home_notebooks');

  // Loading opacity & spinner when tab is clicked
  $('.tabLink').on("click", function(){
    $(document).ajaxStart(function(){
      $("wait").css("display", "block");
      $("#hiddenSpinner .fa-refresh").css("visibility","visible", "display", "absolute", "top", "50%");
    });
    $(document).ajaxComplete(function(){
      $("#wait").css("display", "none");
      $("#txt").css("opacity", "1");
      $("#hiddenSpinner .fa-refresh").css("visibility","hidden")
    });
  });
  
//Newsfeed
    $('#newHomeNotebooksFeed').on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=updated');
      return false; 
    });
  
//Data for RECENT notebooks 
    $("#newHomeNotebooksRecent").on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=recent');
      return false; 
    });
  
//Data for STARRED notebooks
    $("#newHomeNotebooksStars").on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=stars');
      return false; 
    });
  
//Data for RECOMMENDED notebooks
    $("#newHomeNotebooksRecommended").on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=suggested');
      return false; 
    });
  
//Data for YOUR notebooks
    $("#newHomeNotebooksYours").on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=mine');
      return false; 
    });
    
//Data for ALL notebooks
    $("#newHomeNotebooksAll").on("click", function(){
      $("#txt").css("opacity", "0.5");
      $("#newHomePageNotebooks").load('/beta_home_notebooks?type=all');
      return false; 
    });
  
//Data for GROUP notebooks
    $("#newHomeNotebooksGroups").on("click",function(){
      $("#txt").css("text-align", "center");
      $('#newHomePageNotebooks').html('<br> <h1> Coming Soon! :) </h1>')
      return false;
    });
  
//Learn TEMP
    $("#newHomeNotebooksLearn").on("click", function(){
      $("#txt").css("text-align", "center");
      $('#newHomePageNotebooks').load('/beta_notebook?type=learning');
      return false;
    });


  $(document).ready(function(){
    //Make tables look pretty, oh so pretty!
    
    $.fn.sparkline.defaults.line.lineColor = 'black';
    $.fn.sparkline.defaults.line.fillColor  = 'gray';
    $.fn.sparkline.defaults.line.highlightSpotColor ='black';
    $.fn.sparkline.defaults.line.highlightLineColor ='black';

    $('.minimize').shave(125);
    
    $('.tooltip-right').tooltipster({
      maxWidth:500,
      side:'right'
    });
    
    $('.tooltips, .tooltip-title').tooltipster({
      maxWidth:250
    });
  });
});
 
    $.fn.sparkline.defaults.line.lineColor = 'black';
    $.fn.sparkline.defaults.line.fillColor  = 'gray';
    $.fn.sparkline.defaults.line.highlightSpotColor ='black';
    $.fn.sparkline.defaults.line.highlightLineColor ='black';
