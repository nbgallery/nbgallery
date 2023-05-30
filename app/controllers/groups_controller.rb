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
    if(params['show_deprecated'].nil? || params['show_deprecated'] != "true")
      @notebooks = @notebooks.where("deprecated=False")
    end
    respond_to do |format|
      format.html
      format.json {render 'notebooks/index'}
      format.rss {render 'notebooks/index'}
    end
  end

  # XXX DEPRECATED
  # GET /g/:gid/:partial_name
  def deprecated_show
    # Note: partial id collisions are possible, but it's deprecated
    @group = Group.where('gid like ?', "#{params[:id]}%").first!
    redirect_to action: 'show', id: @group.to_param, status: :moved_permanently
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
    message = ""
    errors = group_form_validation(params)
    members = member_list(:new)
    if members[:status] != "success"
      if members[:users].length == 1
        errors += "Could not find user \"" + members[:users].join + "\" to add to the group. "
      else
        errors += "Could not find users \"" + members[:users].join + "\" to add to the group. "
      end
    end
    if errors.length <= 0
        @group = Group.new(
          gid: SecureRandom.uuid,
          name: params[:name],
          description: params[:description],
          url: params[:url]
        )
        update_members(members)
        @group.save
        message = "Group <strong><a href=" + group_path(@group)+ ">" + params[:name] + "</a></strong> has been created successfully."
        flash[:success] = message
        render json: { message: message }, status: :created
    else
        # No flash message. JS will handle it to allow user to correct error.
        render json: { message: "Group creation failed. " + errors }, status: :unprocessable_entity
    end
  end

  # PATCH /groups/:gid
  def update
    errors = group_form_validation(params)
    members = member_list(:update)
    if members[:status] != "success"
      if members[:users].length == 1
        errors += "Could not find user \"" + members[:users].join + "\" to add to the group. "
      else
        errors += "Could not find users \"" + members[:users].join + "\" to add to the group. "
      end
    end
    if errors.length <= 0
      @group.name = params[:name] if params[:name].present?
      @group.description = params[:description] if params[:description].present?
      @group.url = params[:url] if params[:url].present?

      update_members(members)

      if @group.save
        flash[:success] = "Group has been updated successfully."
        render json: { gid: @group.gid }, status: :ok
      else
        render json: @group.errors, status: :unprocessable_entity
      end
    else
      render json: { message: "Group update failed. " + errors }, status: :unprocessable_entity
    end
  end

  # PATCH /groups/:gid/landing
  def landing
    if params[:notebook_id]
      notebook = Notebook.find_by!(uuid: params[:notebook_id])
      raise User::Forbidden, 'Notebook is not owned by this group.' unless
        notebook.owner == @group
    else
      notebook = nil
    end
    is_update = false
    if @group.landing != nil
      is_update = true;
    end
    @group.landing = notebook
    if @group.save
      respond_to do |format|
        format.html {redirect_to group_url}
        if @group.landing_id != nil
          if is_update
            flash[:success] = "Group landing page has been updated successfully."
          else
            flash[:success] = "Group landing page has been set successfully."
          end
        else
          flash[:success] = "Group landing page has been removed successfully."
        end
        format.json {head :no_content}
      end
    else
      render json: @group.errors, status: :unprocessable_entity
    end
  end

  # DELETE /groups/:gid
  def destroy
    @group.destroy
    flash[:success] = "Group has been destroyed successfully."
    head :no_content
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_group
    @group = Group.find(params[:id])
  end

  # Set reference to group landing page notebook
  def set_landing
    @landing = @group.landing if @group&.landing && @user.can_read?(@group.landing)
    clickstream('viewed notebook', notebook: @landing, tracking: "group #{@group.id} landing page") if @landing
  end

  # Verify group ownership
  def verify_group_owner
    raise User::Forbidden, 'You are not an owner of this group.' unless
      @group.owners.include?(@user)
  end

  # Find errors with the group input for creation/edits
  def group_form_validation(params)
    errors = ""
    # Check if group name is missing but user submits anyway
    if params[:name] == ""
      errors += "Group name is missing. Please ensure the input is filled out. "
    end
    params.each do |key, value|
      next unless key.start_with?('username_')
      # Check if all group members have username fields filled out
      if value == ""
        errors += "Group member name is missing. Please ensure the input is filled out or group member row is deleted. "
      end
      # Check if all group members have a role declared
      username_number = key.split("_")[1]
      if !(params.has_key?("role_" + username_number))
        # Error if group member name is declared
        if value != ""
          errors += "Role for a group member \"" + value + "\" is missing. Please ensure the input is filled out or group member row is deleted. "
        # Error if group member name is also not declared
        else
          errors += "Role for group member is missing. Please ensure a role is selected from the dropdown for all added group member rows. "
        end
      end
    end
    return errors
  end

  # Get group membership from params
  def member_list(mode)
    members = {}
    error_users = []

    # Current user is creator of new groups
    members[@user] = :creator if mode == :new

    # Build the member list
    params.each do |key, value|
      # Get user object from username
      next unless key.start_with?('username_')
      user = User.find_by(user_name: value)
      if user.nil?
        # Exclude user lookups as errors when username just missing. Covered in form validation method
        if value != ""
          error_users[error_users.length] = value
        end
        next
      end
      next if user == @user && mode == :new # already added as creator
      # Get corresponding role from params
      suffix = key[9..-1]
      role = params['role_' + suffix].to_sym
      role = :owner if role == :creator # only one creator
      members[user] = role
    end
    if error_users.length > 0
      return { status: "failed", users: error_users }
    end
    return { status: "success", users: members }
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
      update = gm&.owner != owner || gm&.editor != editor
      if !gm || update
        # Existing user - remove old membership before re-adding
        @group.users -= [user] if update

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
