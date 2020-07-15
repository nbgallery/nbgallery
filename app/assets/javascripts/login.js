$(document).ready(function() {
  $("#sign_in_user").on("ajax:success", function(e, data, status, xhr) {
    window.location.reload(true)
  })
  $("#sign_in_user").on("ajax:error", function(e, data, status, xhr) {
    console.log("Failed to log in", data.responseJSON)
    $(".login-flashes p").remove()
    $(".login-flashes").append("<p class='text-danger'>Invalid E-mail or Password</p>")
  })
  $("#sign_up_user").on("ajax:success", function(e, data, status, xhr) {
    console.log("Successfully registered user")
    $(".login-flashes p").remove()
    $(".login-flashes").append("<p class='text-success'>Check your e-mail for a link to confirm your account</p>")
    $(".login-flashes").append("<p class='text-success'>You must confirm your account before you can log in</p>")
  })
  $("#sign_up_user").on("ajax:error", function(e, data, status, xhr) {
    console.log("Failed to register user", data.responseJSON)
    console.log(data.responseJSON)
    $(".login-flashes p").remove()
    if (data.responseJSON.errors.email) {
      $(".login-flashes").append("<p class='text-danger'>E-mail already in use or invalid</p>")
    }
    if (data.responseJSON.errors.user_name) {
      $(".login-flashes").append("<p class='text-danger'>User name already in use or invalid</p>")
    }
  })
  $("#reset_password").on("ajax:success", function(e, data, status, xhr) {
    console.log("Successfully reset password")
    $(".login-flashes p").remove()
    $(".login-flashes").append("<p class='text-success'>Check your e-mail for a link to reset your password</p>")
  })
  $("#reset_password").on("ajax:error", function(e, data, status, xhr) {
    console.log("Failed to reset_password", data.responseJSON)
    $(".login-flashes p").remove()
    $(".login-flashes").append("<p class='text-danger'>Invalid e-mail address</p>")
    $(".login-flashes").append("<p class='text-danger'>Please verify it is correct and try again</p>")
  })
})
