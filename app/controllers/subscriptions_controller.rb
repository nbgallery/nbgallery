# Controller for subscription pages
class SubscriptionsController < ApplicationController

  # GET /subscriptions
  def index
    @subscriptions = Subscription.where(user_id: @user.id)
    SubscriptionMailer.daily_subscription_email
    respond_to do |format|
      format.html
      format.json
    end
  end

  # PATCH /subscriptions/:id/new???
  def update
    subid = params[:subid]
    subtype = params[:type]
    if Subscription.where({user_id: @user.id, sub_type: subtype, sub_id: subid}).length < 1
      if subtype == "group" || subtype == "notebook" || subtype == "user" || subtype == "tag"
        Subscription.create(user_id: @user.id, sub_type: subtype, sub_id: subid)
        flash[:success] = "Successfully added #{subtype} subscription!"
      else
        flash[:error] = "Unknown subscription type. Subscribe icon most likely exists on a page it shouldn't be on. Try refreshing the page and report bug or contact NBGallery support if the issue persists."
      end
    else
      flash[:error] = "You are already subscribed to this #{subtype}. View all your subscriptions on the <a href=#{subscriptions_path}>Subscriptions</a> page."
    end
    redirect_to(:back)
  end

  # DELETE /subscriptions/:id
  def destroy
    id = request.fullpath.split('/').last.to_i
    if (Subscription.exists?(id))
      Subscription.destroy(id)
      flash[:success] = "Subscription has been removed successfully."
    else
      flash[:error] = "The subscription you are trying to delete either does not exists or has already been deleted. Refresh the page or try unsubscribing/viewing your subscriptions on the <a href=#{subscriptions_path}>Subscriptions</a> page. Report the bug or contact NBGallery support if the issue persists."
    end
    redirect_to(:back)
  end
end
