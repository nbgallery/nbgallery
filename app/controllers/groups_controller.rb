# Groups controller
class GroupsController < ApplicationController
  before_action :set_group, only: [:show, :edit, :update, :destroy, :landing]
  before_action :verify_login, except: [:index, :show]
  before_action :verify_group_owner, only: [:edit, :update, :destroy, :landing]

  # GET /groups
  def index
    @groups = Group.readable_by(@user)
  end

  # GET /groups/:gid
  def show
    @notebooks = query_notebooks.where(owner: @group)
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
    end
  end

  # GET /groups/new
  def new
    # TODO
    render layout: false
  end

  # GET /groups/:gid/edit
  def edit
    # TODO
  end

  # POST /groups
  def create
    @group = Group.new(
      gid: SecureRandom.uuid,
      name: params[:name],
      description: params[:description],
      url: params[:url]
    )

    members = member_list(:new)
    update_members(members)

    if @group.save
      render(json: { gid: @group.gid }, status: :created)
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # PATCH /groups/:gid
  def update
    # Handle name change
    if !params[:name].blank? && @group.name != params[:name]
      exists = Group.find_by(name: params[:name])
      if exists && exists.gid != @group.gid
        render json: { message: 'group name already exists' }, status: :unprocessable_entity
        return
      else
        @group.name = params[:name]
      end
    end

    @group.description = params[:description] unless params[:description].blank?
    @group.url = params[:url] unless params[:url].blank?

    members = member_list(:update)
    update_members(members)

    if @group.save
      render json: { gid: @group.gid }, status: :ok
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # PATCH /groups/:gid/landing
  def landing
    if params[:notebook_id]
      notebook = Notebook.find_by!(uuid: params[:notebook_id])
      raise User::Forbidden, 'notebook is not owned by this group' unless
        notebook.owner == @group
    else
      notebook = nil
    end

    @group.landing = notebook
    if @group.save
      respond_to do |format|
        format.html {redirect_to group_url, notice: 'Group landing page was successfully set.'}
        format.json {head :no_content}
      end
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:gid
  def destroy
    @group.destroy
    head :no_content
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.where('gid like ?', "#{params[:id]}%").first!
    # TODO: disambiguate partial id collisions
  end

  # Verify group ownership
  def verify_group_owner
    raise User::Forbidden, 'you are not an owner of this group' unless
      @group.owners.include?(@user)
  end

  # Get group membership from params
  def member_list(mode)
    members = {}

    # Current user is creator of new groups
    members[@user] = :creator if mode == :new

    # Build the member list
    params.each do |key, value|
      # Get user object from username
      next unless key.start_with?('username_')
      user = User.find_by(user_name: value)
      next unless user # TODO: error?
      next if user == @user && mode == :new # already added as creator

      # Get corresponding role from params
      suffix = key[9..-1]
      role = params['role_' + suffix].to_sym
      role = :owner if role == :creator # only one creator
      members[user] = role
    end

    members
  end

  # Add/edit/remove users from group membership
  def update_members(members)
    # Remove any users no longer listed
    @group.users -= (@group.users - members.keys)

    # Add/edit the new list of users
    members.each do |user, role|
      creator = [:creator].include?(role)
      owner = [:creator, :owner].include?(role)
      editor = [:creator, :owner, :editor].include?(role)

      gm = @group.membership.where(user: user).first
      if gm
        # Existing user - update privileges
        gm.owner = owner
        gm.editor = editor
      else
        # New user
        @group.membership << GroupMembership.new(
          user: user,
          group: @group,
          creator: creator,
          owner: owner,
          editor: editor
        )
      end
    end
  end
end
