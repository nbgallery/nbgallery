# User login callbacks
class CallbacksController < Devise::OmniauthCallbacksController
  %i[github facebook google_oauth2].each do |provider|
    define_method provider do
      auth = request.env['omniauth.auth']
      # Find an identity here
      @identity = Identity.find_with_omniauth(auth)

      if @identity.nil?
        Rails.logger.debug('Registering')
        # If no identity was found, create a brand new one here
        begin
          @identity = Identity.create_with_omniauth(auth)
        rescue => e
          Rails.logger.error(e.message)
          redirect_to root_url, flash: { error: e.message.to_s }
          return
        end
      end

      unless signed_in?
        if @identity.user
          @user = @identity.user
          if !@user.approved? && GalleryConfig.registration.require_admin_approval
            error = 'Your account has been registered, but an adminstrator has not yet approved it.'
            redirect_to root_url, flash: { error: error }
          else
            sign_in_and_redirect @user
          end
        end
      end
    end
  end
  def after_sign_in_path_for(_provider)
    @user.errors.add(:email, 'You must specify an e-mail address') unless @user.email
    @user.errors.add(:user_name, 'You must specify a user name') unless @user.user_name
    if @user.valid? and @user.user_name and @user.email
      super @user
    else
      Rails.logger.debug('Trying to go to edit path')
      edit_user_path(@user, flash: { error: 'You must choose a username before you can continue' })
      #finish_signup_path(@user)
    end
  end
end
