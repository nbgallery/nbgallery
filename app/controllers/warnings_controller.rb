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
    @warning.expires = DateTime.strptime("#{params[:expires]} 23:59:59", '%m/%d/%Y %H:%M:%S')
    @warning.user = @user

    if @warning.save
      head :no_content
    else
      render json: @warning.errors, status: :unprocessable_entity
    end
  end

  # DELETE /admin/warning
  def destroy
    @warning&.destroy
    head :no_content
  end
end
