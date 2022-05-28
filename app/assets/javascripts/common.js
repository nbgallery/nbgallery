/* ===================================== */
/* =============== Alerts ============== */
/* ===================================== */
/* ===== Make Alert ===== */
function makeAlert() {
  
}

/* ===== Make Screenreader-Only Alert ===== */
function makeScreenreaderAlert() {

}

/* ===================================== */
/* ==== Expand Textarea as you type ==== */
/* ===================================== */
function autoSize({target:element}) {
  // Only expands if they have the "auto-expand" class and the keydown autoSize event listener
  if(!element.classList.contains('auto-expand'))
    return;
  setTimeout(function(){
    value = element.scrollHeight + 2;
    element.style.cssText = 'height:' + value + 'px';
  },0);
}

/* ===================================== */
/* ========= Character Limits ========== */
/* ===================================== */
function remainingCharacterWarning(length, characterCountElement, maxlength) {
  $(characterCountElement).html( 'Remaining characters: ' + ( maxlength - length ));
  if (maxlength <= length) {
    $(characterCountElement).addClass('error');
  }
  else {
    $(characterCountElement).removeClass('error');
  }
  if (maxlength - length < 50) {
    $(characterCountElement).css('display','block');
  }
  else {
    $(characterCountElement).css('display','none');
  }
}

/* ===================================== */
/* =========== Loading Gif ============= */
/* ===================================== */
function loadingGif() {
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
