# Send mail to users for notebook actions
class SubscriptionMailer < ApplicationMailer
  # Daily subscription email
  def daily_subscription_email(user_id, url)
    @user_id = user_id
    @url = url.chomp('/')

    #===== Initialize variables =====#
    @group_subscriptions = Subscription.where(user_id: @user_id, sub_type: "group")
    @user_subscriptions = Subscription.where(user_id: @user_id, sub_type: "user")
    @tag_subscriptions = Subscription.where(user_id: @user_id, sub_type: "tag")
    @notebook_subscriptions = Subscription.where(user_id: @user_id, sub_type: "notebook")

    # Arrays of notebooks, tags, and groups
    @new_group_notebooks = []
    @new_user_notebooks = []
    @new_tag_notebooks = []
    @new_notebooks = []
    @updated_groups = []
    @updated_users = []
    @updated_tags = []
    @updated_notebooks = []
    @updated_group_notebooks = []
    @updated_user_notebooks = []
    @updated_tag_notebooks = []
    @tag_text_index = []
    @new_tag_index = []

    # Arrays of reviews and comments
    @group_review_updates = []
    @user_review_updates = []
    @tag_review_updates = []
    @notebook_review_updates = []
    @user_review_index = []
    @group_review_index = []
    @tag_review_index = []
    @comment_thread_user_updates = []
    @comment_thread_notebook_updates = []
    @comment_thread_group_updates = []

    # New groups, users, and tags
    @newly_added_groups = []
    @newly_added_users = []
    @newly_added_tags = []

    # Total Counts
    @total_group_notebooks = 0
    @total_tag_notebooks = 0
    @total_user_notebooks = 0
    @total_group_updates = 0
    @total_tag_updates = 0
    @total_user_updates = 0
    @total_notebook_updates = 0;
    private_notebooks = 0

    # Simplify Email
    simplify_email = false

    #===== Group Subscriptions =====#
    @group_subscriptions.each do |element|
      if time_within_last_business_day(Group.find(element.sub_id).updated_at)
        @updated_groups.push(Group.find(element.sub_id))
      end
      sql_statement = "owner_type = 'Group' and owner_id = '#{element.sub_id}' and public = 1"
      @total_group_notebooks += Notebook.where(sql_statement).count
      # For each public notebook that belongs to group, see if any changes in last business day
      Notebook.where(sql_statement).each do |notebook|
        if time_within_last_business_day(notebook.created_at)
          @new_group_notebooks.push(notebook)
        elsif time_within_last_business_day(notebook.updated_at)
          @updated_group_notebooks.push(notebook)
        end
        if Review.exists?(:notebook_id => notebook.id)
          Review.where(:notebook_id => notebook.id).each do |review|
            if time_within_last_business_day(review.updated_at)
              @group_review_updates.push(review)
              @group_review_index.push(element.sub_id)
            end
          end
        end
        sql_statement = "thread_id in (select commontator_threads.id from commontator_threads where commontator_threads.commontable_id=#{notebook.id})"
        Commontator::Comment.where(sql_statement).each do |comment|
          if time_within_last_business_day(comment.updated_at)
            @comment_thread_group_updates.push(comment)
          end
        end
      end
    end

    #===== User Subscriptions =====#
    @user_subscriptions.each do |element|
      sql_statement = "(updater_id = #{element.sub_id}) and public = 1"
      @total_user_notebooks += Notebook.where(sql_statement).count
      # For each public notebook that belongs to or was created by user, see if any changes in last business day
      Notebook.where(sql_statement).each do |notebook|
        if time_within_last_business_day(notebook.created_at)
          @new_user_notebooks.push(notebook)
        elsif time_within_last_business_day(notebook.updated_at)
          @updated_user_notebooks.push(notebook)
        end
        if Review.exists?(:notebook_id => notebook.id)
          Review.where(:notebook_id => notebook.id).each do |review|
            if time_within_last_business_day(review.updated_at)
              @user_review_updates.push(review)
              @user_review_index.push(element.sub_id)
            end
          end
        end
      end
      sql_statement = "creator_id = #{element.sub_id} and creator_type = 'User'"
      Commontator::Comment.where(sql_statement).each do |comment|
        if time_within_last_business_day(comment.updated_at)
          @comment_thread_user_updates.push(comment)
        end
      end
    end

    #===== Tag Subscriptions =====#
    @tag_subscriptions.each do |element|
      # TODO: #360 -- Fix when tag is normalized
      sql_statement = "public = 1 and id in (select tags.notebook_id from tags where tags.tag='#{Tag.find(element.sub_id).tag_text}')"
      @total_tag_notebooks += Notebook.where(sql_statement).count
      # See if any anythings with said tag have had updates, newly created, etc.
      Notebook.where(sql_statement).each do |notebook|
        if time_within_last_business_day(notebook.created_at)
          @new_tag_notebooks.push(notebook)
          @new_tag_index.push(Tag.find(element.sub_id).tag_text)
        elsif time_within_last_business_day(notebook.updated_at)
          @updated_tag_notebooks.push(notebook)
          @tag_text_index.push(Tag.find(element.sub_id).tag_text)
        end
        if Review.exists?(:notebook_id => notebook.id)
          Review.where(:notebook_id => notebook.id).each do |review|
            if time_within_last_business_day(review.updated_at)
              @tag_review_updates.push(review)
              @tag_review_index.push(element.sub_id)
            end
          end
        end
      end
      # See if any new tags user subscribes to were newly applied on a notebook
      # TODO: #360 - Fix when tag is normalized
      Tag.where(:tag => Tag.find(element.sub_id).tag_text).each do |tag|
        if Time.now.strftime("%A") == "Monday"
          if time_within_last_business_day(tag.created_at) && !@new_tag_notebooks.include?(Notebook.find(tag.notebook_id)) && !@updated_tag_notebooks.include?(Notebook.find(tag.notebook_id))
            @newly_added_tags.push(tag)
          end
        end
      end
    end


    #===== Notebook Subscriptions =====#
    @notebook_subscriptions.each do |element|
      if Notebook.find(element.sub_id).public == false
        private_notebooks += 1
        next
      end
      if time_within_last_business_day(Notebook.find(element.sub_id).created_at)
        @new_notebooks.push(Notebook.find(element.sub_id))
      elsif time_within_last_business_day(Notebook.find(element.sub_id).updated_at)
        @updated_notebooks.push(Notebook.find(element.sub_id))
      end
      if Review.exists?(:notebook_id => element.sub_id)
        Review.where(:notebook_id => element.sub_id).each do |review|
          if time_within_last_business_day(review.updated_at)
            @notebook_review_updates.push(review)
          end
        end
      end
      sql_statement = "thread_id in (select commontator_threads.id from commontator_threads where commontator_threads.commontable_id=#{element.sub_id})"
      Commontator::Comment.where(sql_statement).each do |comment|
        if time_within_last_business_day(comment.updated_at)
          @comment_thread_notebook_updates.push(comment)
        end
      end
    end

    #===== Calculate Totals =====#
    # Total group updates
    @total_group_updates = @updated_groups.length + @updated_group_notebooks.length + @group_review_updates.length + @new_group_notebooks.length + @newly_added_groups.length + @comment_thread_group_updates.length
    # Total user updates
    @total_user_updates = @updated_users.length + @updated_user_notebooks.length + @user_review_updates.length + @comment_thread_user_updates.length + @new_user_notebooks.length + @newly_added_users.length
    # Total tag updates
    @total_tag_updates = @updated_tags.length + @updated_tag_notebooks.length + @tag_review_updates.length + @new_tag_notebooks.length + @newly_added_tags.length
    # Total notebook updates
    @total_notebook_updates = @updated_notebooks.length + @notebook_review_updates.length + @new_notebooks.length + @comment_thread_notebook_updates.length
    # Total updates
    @total_updates = @total_group_updates + @total_user_updates + @total_tag_updates + @total_notebook_updates

    #===== Simplify Email Check =====#
    # Check Groups
    @updated_groups.each do |group|
      simplify_email = true if need_to_simplify_email?(group)
    end
    @updated_group_notebooks.each do |notebook|
      simplify_email = true if need_to_simplify_email?(notebook)
    end
    @group_review_updates.each do |review|
      simplify_email = true if need_to_simplify_email?(review)
    end
    @comment_thread_group_updates.each do |comment|
      simplify_email = true if need_to_simplify_email?(comment)
    end
    # Check Users
    if !simplify_email
      @new_user_notebooks.each do |notebook|
        simplify_email = true if need_to_simplify_email?(notebook)
      end
      @updated_user_notebooks.each do |notebook|
        simplify_email = true
      end
      @user_review_updates.each do |review|
        simplify_email = true if need_to_simplify_email?(review)
      end
      @comment_thread_user_updates.each do |comment|
        simplify_email = true if need_to_simplify_email?(comment)
      end
    end
    # Check Tags
    if !simplify_email
      @new_tag_notebooks.each do |notebook|
        simplify_email = true if need_to_simplify_email?(notebook)
      end
      @updated_tag_notebooks.each do |notebook|
        simplify_email = true if need_to_simplify_email?(notebook)
      end
      @tag_review_updates.each do |review|
        simplify_email = true if need_to_simplify_email?(review)
      end
    end
    # Check Notebooks
    if !simplify_email
      @new_notebooks.each do |notebook|
        simplify_email = true if need_to_simplify_email?(notebook)
      end
      @updated_notebooks.each do |notebook|
        simplify_email = true if need_to_simplify_email?(notebook)
      end
      @notebook_review_updates.each do |review|
        simplify_email = true if need_to_simplify_email?(review)
      end
      @comment_thread_notebook_updates.each do |comment|
        simplify_email = true if need_to_simplify_email?(comment)
      end
    end
    @email_needs_to_be_simplified = simplify_email
    #===== Send Email =====#
    mail(to: User.find(@user_id).email,
      subject: "NBGallery Subscriptions - #{Time.now.strftime('%A, %B %d, %Y')}") do |format|
      format.html {render 'daily_subscription_email'}
      format.text {render 'daily_subscription_email'}
    end
  end

  # Return true if time is in last business day
  # (in last 24 hours unless a Monday, then include up to Friday)
  def time_within_last_business_day(time)
    if time + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && time + 3.days > Time.now)
      return true
    end
    return false
  end
end
