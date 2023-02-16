$(document).ready(function() {
  var counter = 0;

  var addRow = function(){
    var newRow = $("<tr>");
    var cols = "";

    cols += '<td><input type="text" class="form-control" name="username_' + counter + '" placeholder="username"/></td>';
    cols += '<td><div class="form-group"><select class="form-control" required name="role_' + counter + '">'
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

  $('#groupToggle').on('click',function(){
      if($('#groupNotebooks').is(':visible')){
        $('#groupToggle span.text').text('view notebooks');
      } else {
        $('#groupToggle span.text').text('view landing notebook');
      };
      $('#groupNotebooks').toggle();
      $('#groupLanding').toggle();
    return false;
  });

  function GetURLParameter(sParam){
    var sPageURL = decodeURIComponent(window.location.search.substring(1));
    var sURLVariables = sPageURL.split('&');
    for(var i = 0; i < sURLVariables.length; i++){
      var sParameterName = sURLVariables[i].split('=');
      if (sParameterName[0] == sParam){
        return sParameterName[1] == undefined ? true: sParameterName[1];
      }
    }
  }

  if (GetURLParameter('page') || GetURLParameter('sort') || GetURLParameter('show_deprecated') || GetURLParameter('use_admin')){
    if($('#groupNotebooks').is(':visible')){
      $('#groupToggle').text(' [view notebooks]');
    } else {
      $('#groupToggle').text(' [view landing notebook]');
      $('#groupNotebooks').toggle();
      $('#groupLanding').toggle();
    };

  }
  if(element=document.querySelector("#groupForm")){
    element.addEventListener('ajax:success', function (event){
      [data, status, xhr] = event.detail;
      location.reload();
    });

    element.addEventListener('ajax:error', function (event){
      console.log(event);
      [data, status, xhr] = event.detail;
      if (status == 'Internal Server Error') {
        makeAlert('error', '#groupForm .alert-container', 'Group creation failed due to an internal server error. Please ensure all required fields of the form have been filled out, else try again later.');
      }
      else {
        makeAlert('error', '#groupForm .alert-container', 'Group creation failed: ' + cleanJSON(data));
      }
    });
  }
  if(element=document.querySelector("#groupManage")){
    element.addEventListener('ajax:success', function (event){
      [data, status, xhr] = event.detail;
      $('.modal').modal('hide');
      location.reload();
    });

    element.addEventListener('ajax:error', function (event){
      [data, status, xhr] = event.detail;
      if (status == 'Internal Server Error'){
        makeAlert('error', '#groupManage .alert-container', 'Group update failed due to an internal server error. Please ensure all fields of the form have been filled out correctly and the group still exists. If it continues, please try again later.');
      }
      else {
        makeAlert('error', '#groupManage .alert-container', 'Group update failed: ' + cleanJSON(data));
      }
    });
  }

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
