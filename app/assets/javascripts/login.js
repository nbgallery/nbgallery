$(document).ready(function() {
  if(element=document.querySelector("#sign_in_user")){
    element.addEventListener("ajax:success", function(event) {
      window.location.reload(true);
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to log in", data);
      makeAlert('error', '#login-content .alert-container', data.error);
    })
  }
  if(element=document.querySelector("#sign_up_user")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully registered user");
      makeAlert('success', '#register-content .alert-container', "Check your e-mail for a link to confirm your account.<br />You must confirm your account before you can log in.");
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to register user", data);
      if (data.errors.email) {
        makeAlert('error', '#register-content .alert-container', "E-mail already in use or invalid");
      }
      if (data.errors.user_name) {
        makeAlert('error', '#register-content .alert-container', "User name already in use or invalid");
      }
    })
  }
  if(element=document.querySelector("#reset_password")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully reset password");
      makeAlert('success', '#reset-password-content .alert-container', "Check your e-mail for a link to reset your password");
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to reset_password", data);
      makeAlert('error', '#reset-password-content .alert-container', 'Invalid e-mail address<br />Please verify it is correct and try again')
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
