class CallbacksController < Devise::OmniauthCallbacksController
  [:github, :facebook, :google_oauth2].each do |provider|
    define_method provider do
      auth = request.env['omniauth.auth']
      # Find an identity here
      @identity = Identity.find_with_omniauth(auth)

      if @identity.nil?
        puts("Registering")
        # If no identity was found, create a brand new one here
        begin
          @identity = Identity.create_with_omniauth(auth)
        rescue => e
          puts e.message
          redirect_to root_url, flash: {error: "This e-mail address is already registered. Please log in using the method already registered"}
          return
        end
      end

      if !signed_in?
        if @identity.user
          # The identity we found had a user associated with it so let's 
          # just log them in here
          @user = @identity.user
          sign_in_and_redirect @user
        end
      end
    end
  end
  def after_sign_in_path_for(provider)
    @user.errors.add(:email, 'You must specify an e-mail address') unless @user.email
    @user.errors.add(:user_name, 'You must specify a user name') unless @user.user_name
    if @user.valid? and @user.user_name and @user.email
      super @user
    else
      puts "Trying to go to edit path"
      edit_user_path(@user)
      #finish_signup_path(@user)
    end
  end
end
