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
  end

  # DELETE /reviews/:id
  def destroy
    @review.destroy
    flash[:success] = "Review for \"#{@notebook.title}\" has been deleted successfully."
    redirect_to reviews_path
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
    @review.comments = params[:comments] if params[:comments].present?
    @review.save
  end

  # PATCH /reviews/:id/claim
  def claim
    if @review.status == 'queued'
      raise User::Forbidden, 'You are not allowed to claim this review.' unless
         @review.reviewable_by(@user)
      @review.status = 'claimed'
      @review.reviewer = @user
      @review.save
      flash[:success] = "Review has been claimed successfully."
      redirect_to(:back)
    else
      flash[:error] = "Review is already claimed."
      redirect_to(:back)
    end
  end

  # PATCH /reviews/:id/unclaim
  def unclaim
    if @review.status == 'claimed'
      @review.status = 'queued'
      @review.reviewer = nil
      @review.save
      flash[:success] = "Review has been unclaimed successfully."
      redirect_to(:back)
    else
      flash[:error] = "Review is not currently claimed."
      redirect_to(:back)
    end
  end

  # PATCH /reviews/:id/complete
  def complete
    if @review.status == 'claimed'
      @review.status = 'completed'
      @review.comments = params[:comments]
      @review.save
      flash[:success] = "Review has been approved successfully."
      redirect_to(:back)
    else
      flash[:error] = "Review is not currently claimed."
      redirect_to(:back)
    end
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
