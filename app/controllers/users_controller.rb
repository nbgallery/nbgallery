# User controller
class UsersController < ApplicationController
  before_action :verify_admin, except: %i[show groups index edit update summary short_form reviews]
  before_action :set_viewed_user, except: %i[index new create short_form]

  # GET /users
  def index
    respond_to do |format|
      format.html do
        verify_admin
        @users = User.all
      end
      format.json do
        verify_admin if params[:prefix].blank? || params[:prefix].size < 3
        @users =
          if params[:prefix].blank?
            User.all
          else
            User.where('user_name LIKE ?', "#{params[:prefix]}%")
          end
        render json: @users.pluck(:user_name).to_json
      end
    end
  end

  # GET /users/:id
  def show
    @notebooks = query_notebooks.where(
      "(owner_type='User' AND owner_id=?) OR (creator_id=?) OR (updater_id=?)",
      @viewed_user.id,
      @viewed_user.id,
      @viewed_user.id
    )
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
    end
  end

  # GET /u/:user_name
  def short_form
    @viewed_user = User.find_by!(user_name: params[:user_name])
    redirect_to action: params[:endpoint] || 'show', id: @viewed_user.to_param, status: :moved_permanently
  end

  # GET /users/:id/summary
  def summary
    min_date = params[:min_date]
    max_date = params[:max_date]
    @counts = @viewed_user.notebook_action_counts(min_date: min_date, max_date: max_date)
    respond_to do |format|
      format.html
      format.json do
        render json: @counts
      end
    end
  end

  # GET /users/:id/groups
  def groups
    @groups = @viewed_user.groups_with_notebooks
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

    # Reviews done by @viewed_user
    reviews = @viewed_user.reviews.joins(:notebook)
    readable = Notebook.readable_join(reviews, @user, true)
    @reviews_performed = readable
      .includes(:revision)
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
      .pluck(:id)
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
    # TODO: admin checkbox should not appear in the view

    raise User::Forbidden, 'you are not allowed to view this page' unless
      @user.id == @viewed_user.id || @user.admin?
  end

  # POST /users
  def create
    @viewed_user = User.new(user_params)

    respond_to do |format|
      if @viewed_user.save
        format.html {redirect_to @viewed_user, notice: 'User was successfully created.'}
        format.json {render :show, status: :created, location: @viewed_user}
      else
        format.html {render :new}
        format.json {render json: @viewed_user.errors, status: :unprocessable_entity}
      end
    end
  end

  # PATCH/PUT /users/:id
  def update
    raise User::Forbidden, 'you are not allowed to view this page' unless
      @user.id == @viewed_user.id || @user.admin?

    respond_to do |format|
      if @viewed_user.update(user_params)
        format.html {redirect_to @viewed_user, notice: 'User was successfully updated.'}
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
      format.html {redirect_to users_url, notice: 'User was successfully destroyed.'}
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
      redirect_to @user, notice: 'Your profile was successfully updated.'
    else
      @show_errors = true
    end
  end

  private

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
