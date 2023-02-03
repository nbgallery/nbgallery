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
      makeAlert('success', '#register-content .alert-container', 'Check your e-mail for a link to confirm your account. You must confirm your account before you can log in.');
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to register user", data);
      if (data.errors.email) {
        if (data.errors.email == "is not a valid email address") {
          makeAlert('error', '#register-content .alert-container', 'Email supplied is not a valid email address. Make double check to make sure it was entered in correctly.');
        }
        else if (data.errors.email == "has already been taken") {
          makeAlert('error', '#register-content .alert-container', 'Email provided is already being used by a user. Please try logging in with that email address if it is yours or please try another one.');
        }
        else {
          makeAlert('error', '#register-content .alert-container', 'There is an issue with your email. Email ' + data.errors.email + '.');
        }
      }
      if (data.errors.user_name) {
        if (data.errors.user_name == "is invalid") {
          makeAlert('error', '#register-content .alert-container', 'Username supplied is invalid. Make sure it contains no spaces or special characters.');
        }
        else if (data.errors.user_name == "has already been taken") {
          makeAlert('error', '#register-content .alert-container', 'Username is already in use. Please select a different one.');
        }
        else {
          makeAlert('error', '#register-content .alert-container', 'There is an issue with your username. Username ' + data.errors.user_name + '.');
        }
      }
      if (data.errors.password) {
        makeAlert('error', '#register-content .alert-container', 'Passwords provided do not meet the requirements for your safety. Password ' + data.errors.password + '.');
      }
      if (data.errors.password_confirmation) {
        makeAlert('error', '#register-content .alert-container', 'Passwords provided do not match. Please try entering them in again.');
      }
    })
  }
  if(element=document.querySelector("#reset_password")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully reset password");
      makeAlert('success', '#reset-password-content .alert-container', 'Check your email for a link to reset your password.');
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to reset_password", data);
      makeAlert('error', '#reset-password-content .alert-container', 'Email address is invalid. Please verify it is correct and try again.')
    })
  }
  if(element=document.querySelector("#reset_password_full")){
    element.addEventListener("ajax:success", function(event) {
      console.log("Successfully reset password");
      makeAlert('success', '', 'Check your email for a link to reset your password.')
    })
    element.addEventListener("ajax:error", function(event) {
      var detail = event.detail;
      var data = detail[0], status = detail[1],  xhr = detail[2];
      console.log("Failed to reset_password", data);
      makeAlert('error', '', 'Email address is invalid. Please verify it is correct and try again.')
    })
  }
})
