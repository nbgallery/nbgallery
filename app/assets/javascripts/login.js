$(document).ready(function() {
  if(element=document.querySelector("#sign_in_user")){
    element.addEventListener("ajax:success", function(event) {
      window.location.reload(true);
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to log in", data);
      $(".login-flashes p").remove();
      $(".login-flashes").append("<p class='text-danger'>" + data.error + "</p>");
    })
  }
  if(element=document.querySelector("#sign_up_user")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully registered user");
      $(".login-flashes p").remove();
      $(".login-flashes").append("<p class='text-success'>Check your e-mail for a link to confirm your account</p>");
      $(".login-flashes").append("<p class='text-success'>You must confirm your account before you can log in</p>");
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to register user", data);
      $(".login-flashes p").remove();
      if (data.errors.email) {
        $(".login-flashes").append("<p class='text-danger'>E-mail already in use or invalid</p>");
      }
      if (data.errors.user_name) {
        $(".login-flashes").append("<p class='text-danger'>User name already in use or invalid</p>");
      }
    })
  }
  if(element=document.querySelector("#reset_password")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully reset password");
      $(".login-flashes p").remove();
      $(".login-flashes").append("<p class='text-success'>Check your e-mail for a link to reset your password</p>");
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to reset_password", data);
      $(".login-flashes p").remove();
      $(".login-flashes").append("<p class='text-danger'>Invalid e-mail address</p>");
      $(".login-flashes").append("<p class='text-danger'>Please verify it is correct and try again</p>");
    })
  }
  if(element=document.querySelector("#reset_password_full")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully reset password");
      makeAlert('success', '', 'Check your e-mail for a link to reset your password')
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to reset_password", data);
      makeAlert('error', '', 'Invalid e-mail address - Please verify it is correct and try again')
    })
  }
})
