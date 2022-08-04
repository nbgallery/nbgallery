# Send mail to users for change requests
class ChangeRequestMailer < ApplicationMailer
  # New change request
  def create(change_request, url)
    @change_request = change_request
    @url = url
    @email_needs_to_be_simplified = simplify_email(change_request)
    mail(
      bcc: @change_request.notebook.owner_email + [@change_request.requestor.email],
      subject: "NBGallery change request submitted"
    )
  end

  # Change request canceled
  def cancel(change_request, url)
    @change_request = change_request
    @url = url
    @email_needs_to_be_simplified = simplify_email(change_request)
    mail(
      bcc: @change_request.notebook.owner_email + [@change_request.requestor.email],
      subject: "NBGallery change request canceled"
    )
  end

  # Change request declined
  def decline(change_request, owner, url)
    @change_request = change_request
    @url = url
    @owner = owner
    @email_needs_to_be_simplified = simplify_email(change_request)
    mail(
      bcc: [@change_request.requestor.email, owner.email],
      subject: "NBGallery change request declined"
    )
  end

  # Change request accepted
  def accept(change_request, owner, url)
    @change_request = change_request
    @url = url
    @owner = owner
    @email_needs_to_be_simplified = simplify_email(change_request)
    mail(
      bcc: [@change_request.requestor.email, owner.email],
      subject: "NBGallery change request accepted"
    )
  end

  def simplify_email(change_request)
    email = render partial: "application/custom_email_needs_to_be_simplified", locals: { change_request: change_request } rescue "False"
    if email == "False" || GalleryConfig.email.force_simplified_emails
      return false
    else
      return true
    end
  end

end
