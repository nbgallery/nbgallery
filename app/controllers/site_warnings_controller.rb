# Controller for warning banner
class SiteWarningsController < ApplicationController
  before_action :verify_admin

  # GET /admin/warning
  def show
  end

  # POST /admin/warning
  def create
    @warning = SiteWarning.new if @warning.nil?
    @warning.level = params[:level]
    @warning.message = params[:message]
    @warning.expires = Time.strptime("#{params[:expires]} 23:59:59 UTC", '%Y-%m-%d %H:%M:%S %Z')
    @warning.user = @user

    if @warning.expires < Time.now
      head :no_content
      flash[:error] = "Expiration date needs to be set for some time in the future."
    elsif @warning.save
      head :no_content
      flash[:success] = "Site Banner has been created successfully."
    else
      head :no_content
      render json: @warning.errors, status: :unprocessable_entity
    end
  end

  # DELETE /admin/warning
  def destroy
    @warning&.destroy
    head :no_content
    flash[:success] = "Site Banner has been deleted successfully."
  end
end
