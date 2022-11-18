# Send mail to users for notebook actions
class NotebookMailer < ApplicationMailer
  # Shared with users
  def share(notebook, owner, emails, message, url)
    @notebook = notebook
    @url = url.chomp('/')
    @owner = owner
    @message = message
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook, @message)
    mail(
      bcc: emails,
      subject: "NBGallery notebook shared with you"
    )
  end

  # Shared with emails that don't have an account
  # e.g. "This was shared but you don't have an account - click here to register!"
  def share_non_member(notebook, owner, emails, message, url)
    @notebook = notebook
    @url = url.chomp('/')
    @owner = owner
    @message = message
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook, @message)
    mail(
      bcc: emails,
      subject: "NBGallery notebook shared with you"
    )
  end

  # Feedback on a notebook
  def feedback(feedback, url)
    @notebook = feedback.notebook
    @url = url.chomp('/')
    @submitter = feedback.user
    @feedback = feedback
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook, @feedback)
    mail(
      bcc: @notebook.owner_email + [@submitter.email],
      subject: "You have feedback on a Jupyter notebook"
    )
  end
end
