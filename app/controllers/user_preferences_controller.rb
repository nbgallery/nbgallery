class UserPreferencesController < ApplicationController
  def index
    @user_preference = UserPreference.find_or_create_by(user_id: @user.id)
  end

  # POST /user_preferences#create
  def create
    @user_preference = UserPreference.find_or_create_by(user_id: @user.id)
    @user_preference.theme = params[:theme] == "default" ? nil : params[:theme]
    @user_preference.high_contrast = params[:high_contrast] == "true" ? true : false
    @user_preference.larger_text = params[:larger_text] == "true" ? true : false
    @user_preference.ultimate_accessibility_mode = params[:ultimate_accessibility_mode] == "true" ? true : false
    @user_preference.full_cells = params[:full_cells] == "true" ? true : false
    @user_preference.disable_row_numbers = params[:disable_row_numbers] == "true" ? true : false
    if @user_preference.save
      flash[:success] = "Successfully updated #{GalleryConfig.site.name} preferences."
      head :no_content
    else
      render json: @user_preference.errors, status: :unprocessable_entity
    end
  end
end
