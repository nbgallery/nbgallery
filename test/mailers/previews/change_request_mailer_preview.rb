# Preview all emails at http://localhost:3000/rails/mailers/change_request_mailer
class ChangeRequestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/create
  def create
    ChangeRequestMailer.create
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/cancel
  def cancel
    ChangeRequestMailer.cancel
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/decline
  def decline
    ChangeRequestMailer.decline
  end

  # Preview this email at http://localhost:3000/rails/mailers/change_request_mailer/accept
  def accept
    ChangeRequestMailer.accept
  end
end
