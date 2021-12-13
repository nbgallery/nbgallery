$(document).ready(function(){
  /* ===================================== */
  /* ============= Tooltips ============== */
  /* ===================================== */
  $('.tooltips').tooltipster({
    animation: 'fade',
    contentAsHTML: true,
    delay: 200,
    maxWidth: 250,
    theme: 'tooltipster-default',
    touchDevices: false,
    trigger: 'hover'
  });
  $('.tooltip-right').tooltipster({
    animation: 'fade',
    contentAsHTML: true,
    delay: 200,
    maxWidth: 250,
    position: 'right',
    theme: 'tooltipster-default',
    touchDevices: false,
    trigger: 'hover'
  });
  $('.tooltip-big').tooltipster({
    animation: 'fade',
    contentAsHTML: true,
    delay: 200,
    maxWidth: 800,
    theme: 'tooltipster-default',
    touchDevices: false,
    trigger: 'hover'
  });
  // Support hover AND focusing to make the help tips appear
  $('.tooltips, .tooltip-right, .tooltip-big').on('focus', function() {
    $(this).tooltipster('show');
  });
  $('.tooltips, .tooltip-right, .tooltip-big').on('blur', function() {
    $(this).tooltipster('hide');
  });
  // Hide all tooltips when user presses ESC key one time
  $(document).keyup(function(e){
    var keycode = (e.keyCode ? event.keyCode : event.which);
    if (keycode == '27' && ($('.tooltipster-base').length)){
      e.preventDefault();
      $('.tooltips, .tooltip-right, .tooltip-big').tooltipster('hide');
      // Just in case one was accidentially focused on without their knowledge
      // and want to know why their ESC didn't do what they expected.
      // Pushing ESC again will preform their expected action.\
      makeScreenreaderAlert('tooltipsDismissAlert', 'All tooltips have been dismissed. Press escape again to preform intended action.');
    }
  });

  /* ===================================== */
  /* ============= Sparkline ============= */
  /* ===================================== */
  $.fn.sparkline.defaults.line.lineColor = 'black';
  $.fn.sparkline.defaults.line.fillColor  = 'gray';
  $.fn.sparkline.defaults.line.highlightSpotColor ='black';
  $.fn.sparkline.defaults.line.highlightLineColor ='black';
  $('.sparkline').sparkline();
  $('.minimize').shave(100);
});

$.fn.sparkline.defaults.line.lineColor = 'black';
$.fn.sparkline.defaults.line.fillColor  = 'gray';
$.fn.sparkline.defaults.line.highlightSpotColor ='black';
$.fn.sparkline.defaults.line.highlightLineColor ='black';
