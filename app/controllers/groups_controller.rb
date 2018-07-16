# Groups controller
class GroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy landing]
  before_action :set_landing, only: %i[show]
  before_action :verify_login, except: %i[index show]
  before_action :verify_group_owner, only: %i[edit update destroy landing]

  # GET /groups
  def index
    @groups = Group.readable_by(@user)
  end

  # GET /groups/:id
  def show
    @notebooks = query_notebooks.where(owner: @group)
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
    end
  end

  # XXX DEPRECATED
  # GET /g/:gid/:partial_name
  def deprecated_show
    deprecated_set_group
    set_landing
    @notebooks = query_notebooks.where(owner: @group)
    respond_to do |format|
      format.html {render 'groups/show'}
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
    @group.name = params[:name] if params[:name].present?
    @group.description = params[:description] if params[:description].present?
    @group.url = params[:url] if params[:url].present?

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
    @group = Group.find(params[:id])
  end

  # XXX DEPRECATED
  def deprecated_set_group
    # Note: partial id collisions are possible
    @group = Group.where('gid like ?', "#{params[:id]}%").first!
  end

  # Set reference to group landing page notebook
  def set_landing
    @landing = @group.landing if @group&.landing && @user.can_read?(@group.landing)
    clickstream('viewed notebook', notebook: @landing, tracking: "group #{@group.id} landing page") if @landing
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
      owner = %i[creator owner].include?(role)
      editor = %i[creator owner editor].include?(role)

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
