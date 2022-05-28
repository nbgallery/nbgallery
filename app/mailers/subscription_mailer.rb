# Send mail to users for notebook actions
class SubscriptionMailer < ApplicationMailer
  # Daily subscription email
  def daily_subscription_email(user_id, url)
    @user_id = user_id
    @url = url
    mail(to: User.find(@user_id).email,
      subject: "NBGallery Subscriptions - #{Time.now.strftime('%A, %B %d, %Y')}") do |format|
      format.html {render 'daily_subscription_email'}
      format.text {render 'daily_subscription_email'}
    end
  end

  def simplify_email(notebook)
    email = render partial: "application/custom_email_needs_to_be_simplified", locals: { notebook: notebook } rescue "False"
    if email == "False"
      return false
    else
      return true
    end
  end

end
