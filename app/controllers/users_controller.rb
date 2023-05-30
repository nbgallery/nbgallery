# User controller
class UsersController < ApplicationController
  before_action :verify_admin, except: %i[show groups index edit update summary short_form reviews userinfo]
  before_action :set_viewed_user, except: %i[index new create short_form userinfo]
  before_action :doorkeeper_authorize!, only: %i[userinfo]
  skip_before_action :authenticate_user!, only: %i[userinfo]

  # GET /users
  def index
    respond_to do |format|
      format.html do
        verify_admin
        @users = User.all
        @users = @users.filter_by_user_name(params[:user_name]) if params[:user_name].present?
        @users = @users.filter_by_first_name(params[:first_name]) if params[:first_name].present?
        @users = @users.filter_by_last_name(params[:last_name]) if params[:last_name].present?
        @users = @users.filter_by_org(params[:org]) if params[:org].present?
        @users = @users.filter_by_approved(params[:approved]) if params[:approved].present?
        @users = @users.filter_by_admin(params[:admin]) if params[:admin].present?
      end
      format.json do
        verify_admin if params[:prefix].blank? || params[:prefix].size < 3
        @users =
          if params[:prefix].blank?
            User.all
          else
            User.where('user_name LIKE ?', "#{params[:prefix]}%")
          end
        render json: @users.map(&:user_name).to_json
      end
    end
  end

  # GET /users/userinfo
  def userinfo
    #Endpoint for acting as an oauth server.  return an error if oauth is not enabled
    raise User::Forbidden, 'You are not allowed to view this page.' unless GalleryConfig.oauth_provider_enabled
    render json: current_resource_owner.to_json
  end

  # GET /users/:id
  def show
    @notebooks = query_notebooks.where(
      "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
      @viewed_user.id,
      @viewed_user.id,
      @viewed_user.id
    )
    @notebooks = @notebooks.where("deprecated=False") unless (params[:show_deprecated] && params[:show_deprecated] == "true")
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
    end
  end

  # GET /u/:user_name(/:endpoint)
  def short_form
    @viewed_user = User.find_by!(user_name: params[:user_name])
    # Keep all existing parameters (e.g. format=json)
    new_params = request.parameters.symbolize_keys
    # Re-route to the new endpoint, if specified
    new_params[:action] = params[:endpoint] || 'show'
    new_params[:id] = @viewed_user.to_param
    # Remove params specific to this endpoint
    new_params.delete(:user_name)
    new_params.delete(:endpoint)
    redirect_to(**new_params, status: :moved_permanently)
  end

  # GET /users/:id/summary
  def summary
    min_date = params[:min_date]
    max_date = params[:max_date]
    respond_to do |format|
      if !max_date.blank? && !min_date.blank? && max_date < min_date
        flash[:error] = "Your 'End Date' must occur after your 'Start Date.'"
        redirect_back(fallback_location: root_path)
        break
      end
      @counts = @viewed_user.notebook_action_counts(min_date: min_date, max_date: max_date)
      @counts[:id] = @user.id
      format.html
      format.json do
        render json: @counts
      end
    end

  end

  # GET /users/:id/groups
  def groups
    @groups = @viewed_user.groups
  end

  # GET /users/:id/detail
  def detail
    @recent_updates = @viewed_user.recent_updates.take(40)
    @recent_actions = @viewed_user.recent_actions.take(20)
    @similar_users = @viewed_user.similar_users.take(20)

    # Note: these are all filtered by the viewed user's permissions
    @recommended_notebooks = @viewed_user.notebook_recommendations.take(20)
    @recommended_groups = @viewed_user.group_recommendations.take(20)
    @recommended_tags = @viewed_user.tag_recommendations.take(20)
  end

  # GET /users/:id/reviews
  def reviews
    # Note: here we are showing reviews related to @viewed_user but only
    # those visible by the current user (@user)
    # Open Reviews done by @viewed_user
    reviews = @viewed_user.reviews.joins(:notebook)
    readable = Notebook.readable_join(reviews, @user, true)
    @reviews_open = readable
      .includes(:revision)
      .where("status = 'queued' or status = 'claimed'")
      .order(updated_at: :desc)

    # Open Reviews done by @viewed_user
    reviews = @viewed_user.reviews.joins(:notebook)
    readable = Notebook.readable_join(reviews, @user, true)
    @reviews_closed = readable
      .includes(:revision)
      .where(status: 'completed')
      .order(updated_at: :desc)

    # Reviews in the queue for which @viewed_user is a recommended reviewer
    reviews = @viewed_user.recommended_reviews.joins(:notebook)
    readable = Notebook.readable_join(reviews, @user, true)
    @reviews_recommended = readable
      .includes(:revision)
      .where(status: 'queued')
      .order(updated_at: :desc)

    # Reviews of notebooks owned/created/updated by @viewed_user
    ids = Notebook
      .where(
        "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
        @viewed_user.id,
        @viewed_user.id,
        @viewed_user.id
      )
      .map(&:id)
    reviews = Review.where(notebook_id: ids).joins(:notebook)
    readable = Notebook.readable_join(reviews, @user, true)
    @reviews_of_notebooks = readable
      .includes(:revision)
      .order(updated_at: :desc)
  end

  # GET /users/new
  def new
    @viewed_user = User.new
  end

  def edit
    raise User::Forbidden, 'You are not allowed to view this page.' unless
      @user.id == @viewed_user.id || @user.admin?
  end

  # POST /users
  def create
    @viewed_user = User.new(user_params)

    respond_to do |format|
      if @viewed_user.save
        format.html {redirect_to @viewed_user}
        flash[:success] = "User was successfully created."
        format.json {render :show, status: :created, location: @viewed_user}
      else
        format.html {render :new}
        format.json {render json: @viewed_user.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /users/:id
  def update
    raise User::Forbidden, 'You are not allowed to view this page.' unless
      @user.id == @viewed_user.id || @user.admin?

    respond_to do |format|
      if @viewed_user.update(user_params)
        format.html {redirect_to @viewed_user}
        flash[:success] = "User was successfully updated."
        format.json {render :show, status: :ok, location: @viewed_user}
      else
        format.html {render :edit}
        format.json {render json: @viewed_user.errors, status: :unprocessable_entity}
      end
    end
  end

  # DELETE /users/:id
  def destroy
    @viewed_user.destroy
    respond_to do |format|
      flash[:success] = "User was successfully destroyed."
      format.json {head :no_content}
    end
  end

  # GET/PATCH /users/:id/finish_signup
  def finish_signup
    # authorize! :update, @user
    return unless request.patch? && params[:user] #&& params[:user][:email]
    if @user.update(user_params)
      @user.skip_reconfirmation!
      #sign_in(@user, :bypass => true)
      redirect_to @user
      flash[:success] = "Your profile was successfully updated."
    else
      @show_errors = true
    end
  end


  private

  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_viewed_user
    @viewed_user =
      if params[:id] == 'me' && @user.member?
        @user
      else
        User.find(params[:id])
      end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    general_fields = %i[email user_name first_name last_name org]
    admin_fields = %i[email user_name first_name last_name org admin]
    fields = @user.admin? ? admin_fields : general_fields
    params.require(:user).permit(*fields)
  end
end
