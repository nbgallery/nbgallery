# Send mail to users for notebook actions
class NotebookMailer < ApplicationMailer
  begin
    include CustomNotebookNotificationConcern
  rescue NameError
    Rails.logger.info("Could not find CustomNotebookNotificationConcern module")
    def process_notification(*args)
      nil
    end
  end
  
  # Shared with users
  def share(notebook, sharer, emails, message, url)
    @notebook = notebook
    @url = url.chomp('/')
    @sharer = sharer
    @message = message
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook, @message)
    mail(
      bcc: emails,
      subject: "NBGallery notebook shared with you"
    )
  end

  # Shared with the owner if one of shared users shares with others
  def notify_owner_of_change(notebook, owner, user, type, emails, message, url)
    @notebook = notebook
    @url = url.chomp('/')
    @owner = owner
    @type = type
    if @type == "shared notebook"
      @sharer = user
      subject = "NBGallery notebook shared with others"
    elsif @type == "ownership change"
      @changer = user
      subject = "NBGallery notebook ownership change"
    end
    @message = message
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook, @message)
    mail(
      bcc: emails,
      subject: subject
    )
  end

  # Shared with emails that don't have an account
  # e.g. "This was shared but you don't have an account - click here to register!"
  def share_non_member(notebook, sharer, emails, message, url)
    @notebook = notebook
    @url = url.chomp('/')
    @sharer = sharer
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

  # inform reviewers of addition to recommended list
  def recommended_reviewer_added(review, user, url)
    @notebook = review.notebook
    @url = url.chomp('/')
    @review = review
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook)
    mail(
      bcc: user.email,
      subject: "You have been added as a recommended reviewer for a Jupyter notebook"
    )
  end

  # inform reviewers of auto claimed notebook
  def auto_claimed_new_version(review, user, url)
    @notebook = review.notebook
    @url = url.chomp('/')
    @review = review
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook)
    mail(
      bcc: user.email,
      subject: "There is a new notebook version available for review."
    )
  end
  
  def notify_owner_unapproved_status(review,user,url)
    @notebook = review.notebook
    @url = url.chomp('/')
    @review = review
    @email_needs_to_be_simplified = need_to_simplify_email?(@notebook)
    mail(
      bcc: user.email,
      subject: "Your notebook has been unapproved by a reviewer."
    )
  end
end
