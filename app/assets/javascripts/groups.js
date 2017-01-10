document.addEventListener('turbolinks:load', function() {
  var counter = 0;

  var addRow = function(){
    var newRow = $("<tr>");
    var cols = "";

    cols += '<td><input type="text" class="form-control" name="username_' + counter + '"/></td>';
    cols += '<td><div class="form-group"><select class="form-control" required=true name="role_' + counter + '">'
    cols += '<option disabled selected value> Pick One </option>'
    cols += '<option value="member"> Member </option>'
    cols += '<option value="editor"> Editor </option>'
    cols += '<option value="owner"> Owner </option>'
    cols += '</select></div></td>';

    cols += '<td><input type="button" class="ibtnDel btn btn-md btn-danger "  value="Delete"></td>';
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
        $('#groupToggle').text(' [view notebooks]');
      } else {
        $('#groupToggle').text(' [view landing notebook]');
      };
      $('#groupNotebooks').toggle();
      $('#groupLanding').toggle();
    return false;
  });

  $('#groupInfo').on('click', function(){
    $(document).trigger("show_group_members", "#{@group.gid}");
    return false;
  });

  $('#groupForm').on('ajax:success', function(){
    bootbox.confirm("Group successfully created", function(result){$('.modal').modal('hide')});
  });  

  $('#groupForm').on('ajax:error', function(xhr,data,response){
    bootbox.alert("Group creation failed: " + data.responseText);
  });  

  $('#groupManage').on('ajax:success', function(){
    $('.modal').modal('hide');
    bootbox.alert("Group successfully updated");
  });  

  $('#groupManage').on('ajax:error', function(xhr,data,response){
    bootbox.alert("Group update failed: " + data.responseText);
  });  

  $('#groupInfo').on('click', function(){
    $('#viewGroup').modal('show');
  });

  $('#editGroup').on('click', function(){
    $('#manageGroup').modal('show');
    return false;
  });

})
