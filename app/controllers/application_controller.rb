# Main application controller
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  layout 'layout.slim'
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :json_request?

  before_action :redirect_if_old
  before_action :set_user
  before_action :set_warning
  before_action :set_page_and_sort
  before_action :check_modern_browser, unless: :skip_modern_browser_check?
  before_action :prepare_exception_notifier
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Generic 404 exception
  class NotFound < RuntimeError
  end

  rescue_from NotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from User::NotAuthorized, with: :user_not_authorized
  rescue_from User::Forbidden, with: :user_forbidden
  rescue_from User::MustAcceptTerms, with: :must_accept_terms
  rescue_from User::MissingRequiredFields, with: :must_set_required_fields
  rescue_from JupyterNotebook::BadFormat, with: :bad_notebook
  rescue_from Notebook::BadUpload, with: :bad_notebook
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
  rescue_from ChangeRequest::NotPending, with: :bad_change_request
  rescue_from ChangeRequest::BadUpload, with: :bad_change_request

  # Redirect from old URL
  def redirect_if_old
    redirect_old_url = GalleryConfig.site.redirect_old_url
    redirect_new_url = GalleryConfig.site.redirect_new_url
    need_redirect = redirect_old_url.present? && redirect_old_url == request.host
    return unless need_redirect
    new_url = "#{request.protocol}#{redirect_new_url}#{request.fullpath}"
    redirect_to(new_url, status: :moved_permanently)
  end

  # Set the current user
  def set_user
    if user_signed_in?
      @user = current_user
      @user.errors.add(:email, 'You must specify an e-mail address') unless @user.email
      @user.errors.add(:user_name, 'You must specify a user name') unless @user.user_name
      if !@user.valid? or !@user.user_name or !@user.email
        raise User::MissingRequiredFields unless editing_or_updating_current_user
      end
      GroupService.refresh_user(@user)
    elsif @user.nil?
      @user = User.new # blank user object - too much breaks otherwise
    end
  end

  def editing_or_updating_current_user
    (%w[edit update].include? params[:action]) &&
      ([current_user.email, current_user.user_name, current_user.id.to_s].include? params[:id])
  end

  def logging_out
    request.path == '/users/sign_out'
  end

  # Set page param for pagination
  def set_page_and_sort
    @page = params[:page].presence || 1
    allowed_sort = %w[updated_at created_at title score views stars runs health trendiness]
    default_sort = params[:q].blank? ? :trendiness : :score
    @sort = (allowed_sort.include?(params[:sort]) ? params[:sort] : default_sort).to_sym
    @sort_dir = (@sort == :title ? :asc : :desc)
  end

  # Set warning page if any
  def set_warning
    @warning =
      if Warning.last.nil?
        nil
      elsif Warning.last.expires.nil? or Warning.last.expires > Time.current
        Warning.last
      end
  end

  # Conditions to skip modern browser check
  def skip_modern_browser_check?
    browser.bot.search_engine? ||
      browser.ua.include?('crawler') ||
      json_request? ||
      rss_request?
  end

  # Check for modern browser
  def check_modern_browser
    ## Update modern browser rules to be IE 11 and not IE9
    Browser.modern_rules.clear
    Browser.modern_rules.tap do |rules|
      rules << ->(b) {b.webkit?}
      rules << ->(b) {b.firefox? && b.version.to_i >= 17}
      rules << ->(b) {b.ie? && b.version.to_i >= 10 && !b.compatibility_view?}
      rules << ->(b) {b.edge? && !b.compatibility_view?}
      rules << ->(b) {b.opera? && b.version.to_i >= 12}
      rules << ->(b) {b.firefox? && b.device.tablet? && b.platform.android? && b.version.to_i >= 14}
    end

    render 'not_modern_browser' unless browser.modern?
  end

  # Disable layout on all JSON requests
  layout(proc {json_request? ? false : 'layout'})

  protected

  def configure_permitted_parameters
    attrs = %i[user_name email password password_confirmation remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: attrs
    devise_parameter_sanitizer.permit :account_update, keys: attrs
  end

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] ||= {}
    request.env['exception_notifier.exception_data'][:user] = @user
  end

  def json_request?
    request.format.json?
  end

  def rss_request?
    request.fullpath.start_with?('/rss')
  end

  def text_error(exception)
    return exception if exception.is_a? String
    text = exception.message
    text += ": #{exception.errors}" if exception.respond_to? :errors
    text
  end

  def json_error(exception)
    return { message: exception } if exception.is_a? String
    obj = { message: exception.message }
    obj[:errors] = exception.errors if exception.respond_to? :errors
    obj
  end

  def record_not_found(exception)
    message = (Rails.env.development? ? exception.message : 'not found')
    respond_to do |format|
      format.html {render 'errors/record_not_found', layout: 'error', status: :not_found}
      format.json {render json: json_error(message), status: :not_found}
    end
  end

  def user_not_authorized(exception)
    respond_to do |format|
      #format.html {render 'errors/user_not_authorized', layout: 'error', status: :unauthorized}
      format.html {redirect_to '/users/sign_in'}
      format.json {render json: json_error(exception), status: :unauthorized}
    end
  end

  def user_forbidden(exception)
    respond_to do |format|
      format.html {render 'errors/user_forbidden', layout: 'error', status: :forbidden}
      format.json {render json: json_error(exception), status: :forbidden}
    end
  end

  def must_accept_terms(_exception)
    respond_to do |format|
      format.html {render 'errors/must_accept_terms', layout: 'error', status: :bad_request}
      format.json {render json: json_error('must accept terms of service'), status: :bad_request}
    end
  end

  def must_set_required_fields(exception)
    #Only redirect if you are not trying to edit yourself
    #Otherwise infinite redirect loop
    Rails.logger.debug('Redirecting to edit path for user')
    respond_to do |format|
      format.html do
        error = 'You must choose a username before you can continue'
        redirect_to edit_user_path(@user), flash: { error: error }
      end
      format.json do
        render json: json_error(exception), status: :unauthorized
      end
    end
  end

  def bad_notebook(exception)
    respond_to do |format|
      format.html do
        render(
          'errors/bad_notebook',
          locals: { exception: exception },
          layout: 'error',
          status: :unprocessable_entity
        )
      end
      format.json do
        render json: json_error(exception), status: :unprocessable_entity
      end
    end
  end

  def bad_change_request(exception)
    respond_to do |format|
      format.html do
        render(
          'errors/bad_change_request',
          locals: { exception: exception },
          layout: 'error',
          status: :unprocessable_entity
        )
      end
      format.json do
        render json: json_error(exception), status: :unprocessable_entity
      end
    end
  end

  def invalid_record(exception)
    # Use exception.record to do something fancy
    respond_to do |format|
      format.html {render text: text_error(exception), status: :unprocessable_entity}
      format.json {render json: json_error(exception), status: :unprocessable_entity}
    end
  end

  def verify_login
    raise User::NotAuthorized, 'must be logged in' unless @user.member?
  end

  def verify_admin
    raise User::Forbidden, 'restricted to admin users' unless @user.admin?
  end

  def verify_accepted_terms
    raise User::MustAcceptTerms unless params[:agree].to_bool
  end

  # Can user read notebook?
  def verify_read(use_admin=false)
    raise User::Forbidden, 'you are not allowed to view this notebook' unless
      @user.can_read?(@notebook, use_admin)
  end

  # Can user read notebook?
  def verify_read_or_admin
    verify_read(true)
  end

  # Can user read notebook?
  def verify_read_not_admin
    verify_read(false)
  end

  # Can user edit notebook?
  def verify_edit(use_admin=false)
    raise User::Forbidden, 'you are not allowed to edit this notebook' unless
      @user.can_edit?(@notebook, use_admin)
  end

  # Can user edit notebook?
  def verify_edit_or_admin
    verify_edit(true)
  end

  # Can user edit notebook?
  def verify_edit_not_admin
    verify_edit(false)
  end

  # Get the staged notebook
  def set_stage
    @stage = Stage.find_by!(uuid: params[:staging_id])
    verify_stage_access
    @jn = @stage.notebook
  end

  # Verify that the user is the one that staged the notebook.
  def verify_stage_access
    allowed = (@stage.user == @user || @user.admin?)
    message = "you are not authorized for stage #{params[:staging_id]}"
    raise User::Forbidden, message unless allowed
  end

  # Add an entry to the actions log
  def clickstream(action, options={})
    user = options[:user] || @user
    return unless user.id
    return if user.respond_to?(:block_clicks?) && @user.block_clicks?
    notebook = options[:notebook] || @notebook
    Click.create(
      user: user,
      org: user.org,
      notebook: notebook,
      action: action,
      tracking: options[:tracking]
    )
  end

  # Helper to get the notebook+summary+suggestion join with page/sort params.
  # Anything that uses the 'notebooks' partial view should probably use this.
  # Note: sometimes the resulting query doesn't work well with count/empty?/etc
  #   so you may have to do a .to_a before checking those -- i.e. counting
  #   the results instead of modifying the SQL to do COUNT().
  def query_notebooks
    Notebook.get(@user, q: params[:q], page: @page, sort: @sort, sort_dir: @sort_dir)
  end

  # Set notebook given various forms of id
  def notebook_from_partial_uuid(id)
    @notebook =
      if GalleryLib.uuid?(id)
        # Full uuid - nbgallery jupyter docker image uses this
        Notebook.find_by!(uuid: id)
      elsif /^[a-z0-9]{8}$/ =~ id
        # Legacy "friendly" URL with uuid prefix and partial title
        # TODO: theoretically possible to have uuid prefix collisions
        Notebook.where('uuid like ?', "#{id}%").first!
      else
        # Rails conventional friendly URL with id and title
        Notebook.find(id)
      end
    request.env['exception_notifier.exception_data'][:notebook] = @notebook
  end

  # Helper for execution stats chart on metrics
  def execution_success_chart(object, sql, name)
    # Build hash of {success => {key => count}, failure => {key => cout}
    executions = object.respond_to?(:executions) ? object.executions : object
    series = executions
      .joins(:code_cell)
      .where('executions.updated_at > ?', 30.days.ago)
      .select("COUNT(*) AS count, success, #{sql} AS #{name}")
      .group("success, #{name}")
      .order(name.to_s)
      .group_by(&:success)
      .map {|success, entries| [success, entries.map {|e| [e.send(name), e.count]}.to_h]}
      .to_h

    # Prep for chart display
    data = [
      { name: 'success', data: series[true] },
      { name: 'failure', data: series[false] }
    ]
    keys =
      if object.is_a?(Notebook) && name == :cell_number
        (0...object.code_cells.count)
      else
        (series[false]&.keys || []) + (series[true]&.keys || [])
      end
    GalleryLib.chart_prep(data, keys: keys)
  end
end
