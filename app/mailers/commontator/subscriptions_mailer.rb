module Commontator
  class SubscriptionsMailer < ActionMailer::Base

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

    def comment_created(comment, recipients)
      setup_variables(comment, recipients)

      mail(@mail_params).tap do |message|
        message.mailgun_recipient_variables = @mailgun_recipient_variables if @using_mailgun
      end
    end

    protected

    def setup_variables(comment, recipients)
      @comment = comment
      @thread = @comment.thread
      @creator = @comment.creator
      @email_needs_to_be_simplified = need_to_simplify_email?(@comment, @comment.body) && need_to_simplify_email?(@thread.commontable, @thread.commontable.title)
      @mail_params = { from: @thread.config.email_from_proc.call(@thread) }

      @recipient_emails = recipients.map do |recipient|
        Commontator.commontator_email(recipient, self)
      end

      @using_mailgun = Rails.application.config.action_mailer.delivery_method == :mailgun

      if @using_mailgun
        @recipients_header = :to
        @mailgun_recipient_variables = {}.tap do |mailgun_recipient_variables|
          @recipient_emails.each { |email| mailgun_recipient_variables[email] = {} }
        end
      else
        @recipients_header = :bcc
      end

      @mail_params[@recipients_header] = @recipient_emails

      @creator_name = Commontator.commontator_name(@creator)
      @commontable_name = Commontator.commontable_name(@thread)
      @comment_url = Commontator.comment_url(@comment, main_app)

      if(@email_needs_to_be_simplified)
        @comment_url = @comment_url.gsub(/notebooks\/(\d+)\-[^#]+/,"notebooks\/\\1")
        @commontable_name = "a notebook"
      end
      @mail_params[:subject] = t(
        'commontator.email.comment_created.subject',
        creator_name: @creator_name,
        commontable_name: @commontable_name,
        comment_url: @comment_url
      )
    end
  end
end
