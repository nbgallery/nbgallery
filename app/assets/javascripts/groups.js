$(document).ready(function() {

  /* ===== Create Group ===== */
  $('#groupForm').on('submit', function(){
    var data = $(this).serialize();
    var url = $(this).attr('action');
    $.ajax({
      url: url,
      data: data,
      type: 'POST',
      success: function(){
        location.reload();
      },
      error: function(response){
        makeAlert('error', '#groupForm .alert-container', response.responseJSON.message);
      }
    });
    return false;
  });

  /* ===== Edit Group ===== */
  $('#groupManage').on('submit', function(){
    var data = $(this).serialize();
    var url = $(this).attr('action');
    $.ajax({
      url: url,
      data: data,
      type: 'PATCH',
      success: function(){
        location.reload();
      },
      error: function(response){
        makeAlert('error', '#groupManage .alert-container', response.responseJSON.message);
      }
    });
    return false;
  });

  /* ===== Helpers ===== */
  let counter = 0;

  let addRow = function(){
    let newRow = $("<tr>");
    let cols = "";

    cols += '<td><input type="text" class="form-control" name="username_' + counter + '" placeholder="username"/></td>';
    cols += '<td><div class="form-group"><select class="form-control" required="required" name="role_' + counter + '">'
    cols += '<option disabled selected value> Pick One </option>'
    cols += '<option value="member"> Member </option>'
    cols += '<option value="editor"> Editor </option>'
    cols += '<option value="owner"> Owner </option>'
    cols += '</select></div></td>';

    cols += '<td><input type="button" class="ibtnDel btn btn-md btn-danger " value="Delete"></td>';
    newRow.append(cols);
    $("table.order-list").append(newRow);
    counter++;
  }

  $("#addrow").on("click", addRow);

  $("#addrowedit").on("click", addRow);

  $("table.order-list").on("click", ".ibtnDel", function (event) {
      $(this).closest("tr").remove();
  });

  /* Expand list of notebooks in favor of viewing landing page */
  $('#groupToggle').on('click',function(){
      if($('#groupNotebooks').is(':visible')){
        $('#groupToggle span.text').text('view notebooks');
      }
      else {
        $('#groupToggle span.text').text('view landing notebook');
      };
      $('#groupNotebooks').toggle();
      $('#groupLanding').toggle();
      $('#groupDescription').toggle();
    return false;
  });

  /* Automatically expand view notebooks or not */
  function GetURLParameter(sParam){
    let sPageURL = decodeURIComponent(window.location.search.substring(1));
    let sURLVariables = sPageURL.split('&');
    for(let i = 0; i < sURLVariables.length; i++){
      let sParameterName = sURLVariables[i].split('=');
      if (sParameterName[0] == sParam){
        return sParameterName[1] == undefined ? true: sParameterName[1];
      }
    }
  }

  if (GetURLParameter('page') || GetURLParameter('sort') || GetURLParameter('show_deprecated') || GetURLParameter('use_admin')){
    if($('#groupNotebooks').is(':visible')){
      $('#groupToggle').text(' [view notebooks]');
    }
    else {
      $('#groupToggle').text(' [view landing notebook]');
      $('#groupNotebooks').toggle();
      $('#groupLanding').toggle();
    };
  }

  /* Generate remaining characters for long group names */
  $('#groupForm input.auto-expand').keyup(function(){
    maxlength = 100;
    length = this.value.length;
    if (length > 2){
      $('#groupFormSubmit').attr('disabled', false);
    }
    $('#groupForm .remaining-characters-warning').html( 'Remaining characters: ' + ( maxlength - length ));
    if (maxlength <= length){
      $('#groupForm .remaining-characters-warning').addClass('error');
    }
    else {
      $('#groupForm .remaining-characters-warning').removeClass('error');
    }
    if (maxlength - length < 50){
      $('#groupForm .remaining-characters-warning').css('display','block');
    }
    else {
      $('#groupForm .remaining-characters-warning').css('display','none');
    }
  })

})
