# Preview all emails at http://localhost:3000/rails/mailers/change_request_mailer
class ChangeRequestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/create
  def create
    ChangeRequestMailer.create(ChangeRequest.first,"http://localhost:3000")
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/cancel
  def cancel
    ChangeRequestMailer.cancel(ChangeRequest.first,"http://localhost:3000")
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/decline
  def decline
    ChangeRequestMailer.decline(ChangeRequest.first, User.first, "http://localhost:3000")
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/accept
  def accept
    ChangeRequestMailer.accept(ChangeRequest.first, User.first, "http://localhost:3000")
  end
end
