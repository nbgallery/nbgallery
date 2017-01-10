# Controller for user preference page
class PreferencesController < ApplicationController
  before_action :set_preference

  # GET /preferences
  def index
    respond_to do |format|
      format.html {render :index}
      format.json {render json: @preference}
    end
  end

  # POST /preferences
  def create
    allowed = @preference.attribute_names.reject {|s| s.end_with?('id', 'at')}
    params.each do |key, value|
      key = key.underscore
      next unless allowed.include?(key)
      if @preference.type_for_attribute(key).class == ActiveRecord::Type::Boolean
        @preference.send("#{key}=".to_sym, value.to_bool)
      else
        @preference.send("#{key}=".to_sym, value)
      end
    end

    if @preference.save
      head :no_content
    else
      render json: @preference.errors, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_preference
    @preference = @user.preference
  end
end
