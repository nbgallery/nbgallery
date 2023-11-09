# Controller for execution environments
class EnvironmentsController < ApplicationController
  before_action :verify_login
  before_action :set_viewed_user
  before_action :set_environment, only: %i[show update destroy edit]

  # GET /environments
  def index
    respond_to do |format|
      format.html do
        # Show all the user's environments
        @environments = Environment.where(user: @viewed_user)
      end
      format.json do
        # If one of them is marked default, just return that one.
        # Otherwise return them all so the GUI can prompt to select one.
        default = Environment.where(user: @viewed_user, default: true).first
        @environments = default ? [default] : Environment.where(user: @viewed_user)
      end
    end
  end

  # GET /environments/:name
  def show
    head :no_content
  end

  # POST /environments
  def create
    @environment =
      Environment.find_by(user: @viewed_user, name: params[:name].strip) ||
      Environment.find_by(user: @viewed_user, url: params[:url].strip) ||
      Environment.new(user: @viewed_user, default: false)
    handle_create_or_update("Environment has been successfully created.")
  end

  # PATCH /environments/:name
  def update
    handle_create_or_update("Environment has been successfully updated.")
  end

  # DELETE /environments/:name
  def destroy
    @environment.destroy
    flash[:success] = "Environment has been deleted successfully."
    head :no_content
  end

  private

  # Common code for create and update
  def handle_create_or_update(success_message)
    @environment.name = params[:name].strip if params[:name].present?
    @environment.url = params[:url].strip if params[:url].present?
    @environment.default = params[:default].to_bool
    # The usersave paramter is how we tell the difference between a user saving
    # the form versus the environment registration pligin triggering again.
    if(@environment.new_record? || params[:usersave])
      if params[:user_interface].present?
        @environment.user_interface = params[:user_interface].strip
      end
    end
    if @environment.save
      if @environment.default
        # Set all other environments to non-default
        Environment
          .where('user_id = ? AND id != ?', @viewed_user.id, @environment.id)
          .find_each {|e| e.update(default: false)}
      end
      flash[:success] = success_message
      head :no_content
    else
      render json: @environment.errors, status: :unprocessable_entity
    end
  end

  # Set the environment object to use
  def set_environment
    if params[:id].to_i.is_a? Integer
      @environment = Environment.find(params[:id].to_i)
    else
      @environment = Environment.find_by!(user: @user, name: params[:id])
    end
  end

  def set_viewed_user
    user = @user
    user_id = @user.id
    url = request.path.split("/")
    if url[1] == "users" && url[2] != nil
      if url[2].include?("-")
        user_id = url[2].split("-")[0].to_i
      else
        user_id = url[2].to_i
      end
    end
    if @user.id != user_id
      raise User::Forbidden unless
        @user.admin?
      user = User.find(user_id)
    end
    @viewed_user = user
  end
end
