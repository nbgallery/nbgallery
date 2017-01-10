# Send mail to users for change requests
class ChangeRequestMailer < ApplicationMailer
  # New change request
  def create(change_request, url)
    @change_request = change_request
    @url = url
    mail(
      to: @change_request.notebook.owner_email,
      cc: @change_request.requestor.email,
      from: @change_request.requestor.email,
      subject: "#{GalleryConfig.site.name} change request submitted"
    )
  end

  # Change request canceled
  def cancel(change_request, url)
    @change_request = change_request
    @url = url

    mail(
      to: @change_request.notebook.owner_email,
      cc: @change_request.requestor.email,
      from: @change_request.requestor.email,
      subject: "#{GalleryConfig.site.name} change request canceled"
    )
  end

  # Change request declined
  def decline(change_request, owner, url)
    @change_request = change_request
    @url = url
    @owner = owner

    mail(
      to: @change_request.requestor.email,
      cc: owner.email,
      from: owner.email,
      subject: "#{GalleryConfig.site.name} change request declined"
    )
  end

  # Change request accepted
  def accept(change_request, owner, url)
    @change_request = change_request
    @url = url
    @owner = owner

    mail(
      to: @change_request.requestor.email,
      cc: owner.email,
      from: owner.email,
      subject: "#{GalleryConfig.site.name} change request accepted"
    )
  end
end
