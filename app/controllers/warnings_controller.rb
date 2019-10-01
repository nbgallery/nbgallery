# Controller for warning banner
class WarningsController < ApplicationController
  before_action :verify_admin

  # GET /admin/warning
  def show
  end

  # POST /admin/warning
  def create
    @warning = Warning.new if @warning.nil?
    @warning.level = params[:level]
    @warning.message = params[:message]
    @warning.expires = Time.strptime("#{params[:expires]} 23:59:59 UTC", '%m/%d/%Y %H:%M:%S %Z')
    @warning.user = @user

    if @warning.expires < Time.now
      head :no_content
      flash[:error] = "Expiration date needs to be set for some time in the future."
    elsif @warning.save
      head :no_content
      flash[:success] = "Site Banner has been created successfully."
    else
      head :no_content
      flash[:error] = "Your request cannot be preformed at this time. Unknown error: '#{@warning.errors}.'"
    end
  end

  # DELETE /admin/warning
  def destroy
    @warning&.destroy
    head :no_content
    flash[:success] = "Site Banner has been deleted successfully."
  end
end
