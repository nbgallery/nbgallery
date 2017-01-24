# Main application mailer
class ApplicationMailer < ActionMailer::Base
  default from: GalleryConfig.email.general_from
  layout 'mailer'
end
