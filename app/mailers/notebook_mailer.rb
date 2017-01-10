# Send mail to users for notebook actions
class NotebookMailer < ApplicationMailer
  # Shared with users
  def share(notebook, owner, emails, message, url)
    @notebook = notebook
    @url = url
    @owner = owner
    @message = message
    mail(
      to: emails,
      cc: owner.email,
      from: owner.email,
      subject: "#{GalleryConfig.site.name} notebook shared with you"
    )
  end

  # Shared with emails that don't have an account
  def share_non_member(notebook, owner, emails, message, url)
    @notebook = notebook
    @url = url
    @owner = owner
    @message = message
    mail(
      to: owner.email,
      bcc: emails,
      from: owner.email,
      subject: "#{GalleryConfig.site.name} notebook shared with you"
    )
  end

  # Feedback on a notebook
  def feedback(feedback, url)
    @notebook = feedback.notebook
    @submitter = feedback.user
    @feedback = feedback
    @url = url
    mail(
      to: @notebook.owner_email,
      cc: @submitter.email,
      from: @submitter.email,
      subject: 'You have feedback on a Jupyter notebook'
    )
  end
end
