# Preview all emails at http://localhost:3000/rails/mailers/notebook_mailer
class NotebookMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notebook_mailer/share
  def share
    NotebookMailer.share
  end

  # Preview this email at http://localhost:3000/rails/mailers/notebook_mailer/feedback
  def feedback
    NotebookMailer.feedback
  end
end
