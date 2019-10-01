# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/subscription_mailer
  def daily_subscription_email
    SubscriptionMailer.daily_subscription_email(User.first.id,"http://localhost:3000")
  end
end
