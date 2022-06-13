/* ===================================== */
/* =============== Alerts ============== */
/* ===================================== */
/* ===== Make Inline Alert ===== */
function makeAlert(type, element_within, message){
  if (element_within == ''){
    element_within = '#main .alert-container:first';
  }
  // NOTE - this shall only be used to generate messages on pages that are not going to be reloaded. If you wish to reload the page AND have an alert when it loads, alert needs to be generated from backend.
  if (type == "success"){
    $(element_within).prepend("<div class='alert alert-success' role='alert'><i aria-hidden='true' class='fa fa-check-circle'></i>" + message + "<button aria-label='Dismiss alert' class='close' data-dismiss='alert'>&times;</button></div>");
  }
  else if (type = "error"){
    $(element_within).prepend("<div class='alert alert-error' role='alert'><i aria-hidden='true' class='fa fa-times-circle'></i>" + message + "<button aria-label='Dismiss alert' class='close' data-dismiss='alert'>&times;</button></div>");
  }
  else if (type == "warning"){
    $(element_within).prepend("<div class='alert alert-warning' role='alert'><i aria-hidden='true' class='fa fa-exclamation-triangle'></i>" + message + "<button aria-label='Dismiss alert' class='close' data-dismiss='alert'>&times;</button></div>");
  }
  else {
    $(element_within).prepend("<div class='alert alert-warning' role='alert'><i aria-hidden='true' class='fa fa-info-circle'></i>" + message + "<button aria-label='Dismiss alert' class='close' data-dismiss='alert'>&times;</button></div>");
  }
  $(element_within).focus();
  $(element_within).get(0).scrollIntoView({ block: "center", behavior: "smooth" });
}

/* ===== Make Screenreader-Only Alert ===== */
function makeScreenreaderAlert(element_id, on_message, off_message){
  var element = '#' + element_id;
  if ($(element).length){
    $(element).text(message);
  }
  else {
    $('#screenreaderAlerts').apend('<div id="' + element_id + '" role="alert">' + message + '</div>');
  }
}

/* ===================================== */
/* ========= Clean JSON Parse ========== */
/* ===================================== */
function cleanJSON(json){
  var keys = Object.keys(json);
  var string = '';
  for (let i = 0; i < keys.length; i++){
    string += keys[i] + ' ' + json[keys[i]];
    if (i + 1 != keys.length){
      if (keys.length >= 3 && i + 2 == keys.length){
        string += ', and '
      }
      else if (keys.length > 2){
        string += ', '
      }
      else if (keys.length == 2){
        string += ' and '
      }
    }
    else {
      string += '.'
    }
  }
  return string;
}

/* ======================================= */
/* ===== Expand Textarea as you type ===== */
/* ======================================= */
function autoSize({target:element}){
  // Only expands if they have the "auto-expand" class and the keydown autoSize event listener
  if (!element.classList.contains('auto-expand'))
    return;
  setTimeout(function(){
    value = element.scrollHeight + 2;
    element.style.cssText = 'height:' + value + 'px';
  },0);
}

/* ===================================== */
/* ========= Character Limits ========== */
/* ===================================== */
function remainingCharacterWarning(length, characterCountElement, maxlength){
  $(characterCountElement).html( 'Remaining characters: ' + ( maxlength - length ));
  if (maxlength <= length){
    $(characterCountElement).addClass('error');
  }
  else {
    $(characterCountElement).removeClass('error');
  }
  if (maxlength - length < 50){
    $(characterCountElement).css('display','block');
  }
  else {
    $(characterCountElement).css('display','none');
  }
}

/* ===================================== */
/* =========== Loading Gif ============= */
/* ===================================== */
function loadingGif(){
  $(document).ajaxStart(function(){
    $('#hiddenSpinner').addClass("loading");
    $('#hiddenSpinner').attr("aria-live","assertive");
  });
  $(document).ajaxComplete(function(){
    $("#hiddenSpinner").removeClass("loading");
    $('#hiddenSpinner').attr("aria-live","off");
    $(document).unbind('ajaxStart');
    $(document).unbind('ajaxComplete');
  });
}
