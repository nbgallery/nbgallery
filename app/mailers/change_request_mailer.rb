# Send mail to users for change requests
class ChangeRequestMailer < ApplicationMailer
  # New change request
  def create(change_request, url)
    @change_request = change_request
    @url = url
    mail(
      bcc: @change_request.notebook.owner_email + [@change_request.requestor.email],
      subject: "NBGallery change request submitted"
    )
  end

  # Change request canceled
  def cancel(change_request, url)
    @change_request = change_request
    @url = url

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

    mail(
      bcc: [@change_request.requestor.email, owner.email],
      subject: "NBGallery change request accepted"
    )
  end
end
