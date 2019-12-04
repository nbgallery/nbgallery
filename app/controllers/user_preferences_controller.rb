class UserPreferencesController < ApplicationController
  def index
    @user_preference = UserPreference.find_or_create_by(user_id: @user.id)
  end

  # POST /user_preferences#create
  def create
    @user_preference = UserPreference.find_or_create_by(user_id: @user.id)
    if params[:theme] == "default"
      @user_preference.theme = nil
    else
      @user_preference.theme = params[:theme]
    end
    @user_preference.timezone = params[:timezone]
    if params[:high_contrast] == "true"
      @user_preference.high_contrast = TRUE
    else
      @user_preference.high_contrast = FALSE
    end
    if params[:larger_text] == "true"
      @user_preference.larger_text = TRUE
    else
      @user_preference.larger_text = FALSE
    end
    if params[:ultimate_accessibility_mode] == "true"
      @user_preference.ultimate_accessibility_mode = TRUE
    else
      @user_preference.ultimate_accessibility_mode = FALSE
    end
    @user_preference.save
    flash[:success] = "Successfully updated #{GalleryConfig.site.name} preferences."
    redirect_to(:back)
  end
end
