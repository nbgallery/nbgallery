# Main application mailer
class ApplicationMailer < ActionMailer::Base
  default from: GalleryConfig.email.general_from
  layout 'mailer'

  def need_to_simplify_email?(object, message="")
    if GalleryConfig.email.force_simplified_emails
      return true
    end
    if object.respond_to?(:simplify_email?)
      return object.simplify_email?(message)
    else
      return false
    end
  end

end
