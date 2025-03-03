# Controller for reviews
class ReviewsController < ApplicationController
  before_action :set_review, except: [:index]
  before_action :verify_login
  before_action :verify_notebook_readable, except: [:index]
  before_action :verify_reviewer, only: [:complete]
  before_action :verify_reviewer_or_admin, only: %i[unclaim update]
  before_action :verify_admin, only: [:destroy]

  # GET /reviews
  def index
    @reviews = Review.joins(:notebook)
    @reviews = @reviews.where(revtype: params[:type]) if params[:type].present?
    @reviews = @reviews.where(status: params[:status]) if params[:status].present?
    @reviews = Notebook
      .readable_join(@reviews, @user, true)
      .includes(:revision)
      .order(updated_at: :desc)
  end

  # GET /reviews/:id
  def show
    latest_history = ReviewHistory.where(:review_id => @review.id).order(id: :desc).limit(1)
    if latest_history.exists?
      if latest_history.first.comment.present?
        @last_comment = latest_history.first.comment
      else
        @last_comment = "(None)"
      end
    else
      @last_comment = @review.comment
    end
  end

  # GET /reviews/:id/history
  def history
    @review_history = ReviewHistory.where(:review_id => @review.id)
    @notebook = Notebook.find(@review.notebook_id)
  end

  # DELETE /reviews/:id
  def destroy
    @review.destroy
    flash[:success] = "Review for \"#{@notebook.title}\" has been deleted successfully."
    redirect_to reviews_path
  end

  # POST /reviews/:id/add_reviewer
  def add_reviewer
    if @user.can_edit?(@review.notebook,true)
      new_reviewers = []
      usernames = params[:users].gsub(/\s+/,"").split(",")
      usernames.each do |username|
        @new_user = User.find_by(user_name: username)
        if @new_user.present?
          if not @review.recommended_reviewer?(@new_user)
              if @user.name != username || @user.admin?
                new_reviewers.push RecommendedReviewer.new(
                  review: @review,
                  user_id: @new_user.id
                )
              else
                flash[:error] = "Error: Cannot add yourself as a reviewer!"
                break
              end
          else
            flash[:error] = "Error: User #{@new_user.name} is already recommended!"
            break
          end
        else
          flash[:error] = "Error: User #{username} does not exist!"
          break
        end
      end

      if new_reviewers.count == usernames.count 
        RecommendedReviewer.import(new_reviewers)
        flash[:success] = "You have successfully added new recommended reviewers."
      end
      redirect_to review_path(@review)
    else
      head :forbidden
    end
  end

  # DELETE /reviews/:id/remove_reviewer
  def remove_reviewer
    if @user.can_edit?(@review.notebook,true)
      reviewers_to_del = params[:del_users].gsub(/\s+/,"").split(",")
      reviewers_to_del.each do |username|
        user_id = User.find_by(user_name: username).id
        RecommendedReviewer.find_by(review_id: @review.id, user_id: user_id).destroy
      end 
      flash[:success] = "You have successfully been removed selected reviewers."
      redirect_to review_path(@review), status: 303
    else
      head :forbidden
    end
  end

  # DELETE /reviews/:id/remove_self_as_reviewer
  def remove_self_as_reviewer
    RecommendedReviewer.find_by(review_id: @review.id, user_id: @user.id).destroy
    flash[:success] = "You have successfully been removed as a recommended reviewer."
    redirect_to review_path(@review), status: 303
  end

  # PATCH/PUT /reviews/:id
  def update
    if params[:revision].present?
      @review.revision =
        if params[:revision] == 'latest'
          @review.notebook.revisions.last
        else
          @review.notebook.revisions.find_by!(commid_id: params[:revision])
        end
    end
    @review.comment = params[:comment] if params[:comment].present?
    @review.save
  end

  # PATCH /reviews/:id/claim
  def claim
    if @review.status == 'queued'
      raise User::Forbidden, 'You are not allowed to claim this review.' unless
         @review.reviewable_by(@user)
      @review.status = 'claimed'
      @review.reviewer = @user
      ReviewHistory.create(:review_id => @review.id, :user_id => @user.id, :action => 'claimed', :comment =>  params[:comment], :reviewer_id => @review.reviewer_id)
      @review.save
      flash[:success] = "Review has been claimed successfully."
    else
      flash[:error] = "Review is already claimed."
    end
    redirect_to review_path(@review)
  end

  # PATCH /reviews/:id/unclaim
  def unclaim
    if @review.status == 'claimed'
      @review.status = 'queued'
      @review.reviewer = nil
      ReviewHistory.create(:review_id => @review.id, :user_id => @user.id, :action => 'unclaimed', :comment =>  params[:comment], :reviewer_id => @review.reviewer_id)
      @review.save
      flash[:success] = "Review has been unclaimed successfully."
    else
      flash[:error] = "Review is not currently claimed."
    end
    redirect_to review_path(@review)
  end

  # PATCH /reviews/:id/complete
  def complete
    if @review.status == 'claimed'
      @review.status = 'approved'
      @review.comment = params[:comment]
      ReviewHistory.create(:review_id => @review.id, :user_id => @user.id, :action => 'approved', :comment =>  @review.comment, :reviewer_id => @review.reviewer_id)
      @review.save
      flash[:success] = "Review has been approved successfully."
    else
      flash[:error] = "Review is not currently claimed."
    end
    redirect_to review_path(@review)
  end

  private

  # Look up review
  def set_review
    @review = Review.find(params[:id])
    @notebook = @review.notebook
  end

  # Notebook must be readable to see reviews
  def verify_notebook_readable
    raise User::Forbidden, 'You are not allowed to view this review.' unless
      @user.can_read?(@notebook, true)
  end

  # Only reviewer can complete
  def verify_reviewer
    raise User::Forbidden, 'Only the reviewer may perform this action.' unless
      @review.reviewer == @user
  end

  # Only reviewer or admin can unclaim
  def verify_reviewer_or_admin
    raise User::Forbidden, 'Only the reviewer may perform this action.' unless
      @review.reviewer == @user || @user.admin?
  end
end
