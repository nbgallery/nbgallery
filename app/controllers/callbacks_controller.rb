# User login callbacks
class CallbacksController < Devise::OmniauthCallbacksController
  %i[github facebook google_oauth2 gitlab azure_activedirectory_v2].each do |provider|
    define_method provider do
      auth = request.env['omniauth.auth']
      # Find an identity here
      @identity = Identity.find_with_omniauth(auth)

      if @identity.nil?
        Rails.logger.debug('Registering')
        # If no identity was found, create a brand new one here
        begin
          @identity = Identity.create_with_omniauth(auth)
        rescue StandardError => e
          Rails.logger.error(e.message)
          flash[:error] = "#{e.message.to_s}"
          redirect_to root_url
          return
        end
      end

      unless signed_in?
        if @identity.user
          @user = @identity.user
          if !@user.approved? && GalleryConfig.registration.require_admin_approval
            flash[:error] = "Your account has been registered, but an adminstrator has not yet approved it."
            redirect_to root_url
            return
          else
            sign_in @user
            redirect_to root_url
            return
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
      flash[:error] = "You must choose a username before you can continue."
      redirect_to edit_user_path(@user)
      #finish_signup_path(@user)
    end
  end
end
