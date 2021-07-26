# Functions to run on a periodic basis
module ScheduledJobs
  class << self
    def job_files
      files = Dir[Rails.root.join('config', 'cronic.d', '*.rb')]
      GalleryConfig.directories.extensions.each do |dir|
        files += Dir[File.join(dir, '*', 'cronic.d', '*.rb')]
      end
      files
    end

    def log(message)
      message = "#{Time.current}: #{message}"
      Rails.logger.info(message)
      # Print to stdout so it goes to cronic.log too
      # rubocop: disable Rails/Output
      puts message if defined?(Cronic::Scheduler) || !GalleryConfig.scheduler.internal
      # rubocop: enable Rails/Output
    end

    def run(name)
      if Rails.env.development? && ENV['NOJOBS']
        log("SCHEDULER: jobs disabled; skipping #{name}")
        return
      end
      log("SCHEDULER: running #{name}")
      start = Time.current
      send(name)
      time = Time.current - start
      log("SCHEDULER: #{name} complete (#{time.to_i}s)")
    rescue StandardError => ex
      log("SCHEDULER: error running #{name}: #{ex.class}: #{ex.message}")
    end

    def hello
      log('Hello, world!')
    end

    def similarity_scores
      # These are used for notebook suggestions.
      start = Time.current
      status = NotebookSimilarity.compute_all
      log("COMPUTE: notebook similarity #{Time.current - start}")
      log("COMPUTE:   -- #{status}")

      start = Time.current
      status = UsersAlsoView.matrix_compute
      log("COMPUTE: users also viewed matrix #{Time.current - start}")
      log("COMPUTE:   -- #{status}")

      start = Time.current
      status = UserSimilarity.matrix_compute
      log("COMPUTE: user similarity matrix #{Time.current - start}")
      log("COMPUTE:   -- #{status}")
    end

    def recommendations
      # Notebook recommendations first -
      # they're used as input for tag/group recommendations.
      start = Time.current
      status = SuggestedNotebook.compute_all
      log("COMPUTE: notebook recommendations #{Time.current - start}")
      log("COMPUTE:   -- #{status}")

      start = Time.current
      SuggestedGroup.compute_all
      log("COMPUTE: group recommendations #{Time.current - start}")

      start = Time.current
      SuggestedTag.compute_all
      log("COMPUTE: tag recommendations #{Time.current - start}")
    end

    def reviews
      start = Time.current
      Review.generate_queue
      log("COMPUTE: review queue #{Time.current - start}")

      start = Time.current
      RecommendedReviewer.recommend_technical_reviewers
      log("COMPUTE: technical reviewers #{Time.current - start}")

      start = Time.current
      RecommendedReviewer.recommend_functional_reviewers
      log("COMPUTE: functional reviewers #{Time.current - start}")

      start = Time.current
      RecommendedReviewer.recommend_compliance_reviewers
      log("COMPUTE: compliance reviewers #{Time.current - start}")
    end

    def nightly_computation
      log('COMPUTE: beginning nightly computation')
      similarity_scores
      recommendations
      reviews
      log('COMPUTE: finished nightly computation')
    end

    def notebook_dailies
      NotebookDaily.age_off
      NotebookDaily.compute_all
    end

    def age_off
      Stage.age_off
      ChangeRequest.age_off
    end

    def notebook_summaries
      NotebookSummary.compute_all
    end

    def user_summaries
      UserSummary.generate_all
    end

    def daily_subscription_email
      group_subscriptions = nil; user_subscriptions = nil; tag_subscriptions = nil; notebook_subscriptions = nil;
      sql_statement = "id in (select user_id from subscriptions)"
      User.where(sql_statement).each do |user|
        sendEmail = false;
        catch (:sendEmail) do
          # Initialize variables
          group_subscriptions = Subscription.where(user_id: user.id, sub_type: "group")
          user_subscriptions = Subscription.where(user_id: user.id, sub_type: "user")
          tag_subscriptions = Subscription.where(user_id: user.id, sub_type: "tag")
          notebook_subscriptions = Subscription.where(user_id: user.id, sub_type: "notebook")
          # Check each subscription belonging to that user to see if there have been any changes, or else don't send the email
          group_subscriptions.each do |element|
            if Group.find(element.sub_id).updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && Group.find(element.sub_id).updated_at + 3.days > Time.now)
              sendEmail = true
              throw :sendEmail
            end
            sql_statement = "owner_type = 'Group' and owner_id = '#{element.sub_id}' and public = 1"
            Notebook.where(sql_statement).each do |notebook|
              if notebook.created_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.created_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              elsif notebook.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.updated_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              end
              if Review.exists?(:notebook_id => notebook.id)
                Review.where(:notebook_id => notebook.id).each do |review|
                  if review.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && review.updated_at + 3.days > Time.now)
                    sendEmail = true
                    throw :sendEmail
                  end
                end
              end
              sql_statement = "thread_id in (select commontator_threads.id from commontator_threads where commontator_threads.commontable_id=#{notebook.id})"
              Commontator::Comment.where(sql_statement).each do |comment|
                if comment.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && comment.updated_at + 3.days > Time.now)
                  sendEmail = true
                  throw :sendEmail
                end
              end
            end
          end
          user_subscriptions.each do |element|
            sql_statement = "(updater_id = #{element.sub_id}) and public = 1"
            Notebook.where(sql_statement).each do |notebook|
              if notebook.created_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.created_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              elsif notebook.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.updated_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              end
              if Review.exists?(:notebook_id => notebook.id)
                Review.where(:notebook_id => notebook.id).each do |review|
                  if review.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && review.updated_at + 3.days > Time.now)
                    sendEmail = true
                    throw :sendEmail
                  end
                end
              end
            end
            sql_statement = "creator_id = #{element.sub_id} and creator_type = 'User'"
            Commontator::Comment.where(sql_statement).each do |comment|
              if comment.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && comment.updated_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              end
            end
          end
          tag_subscriptions.each do |element|
            sql_statement = "public = 1 and id in (select tags.notebook_id from tags where tags.tag='#{Tag.find(element.sub_id).tag}')"
            Notebook.where(sql_statement).each do |notebook|
              if notebook.created_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.created_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              elsif notebook.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && notebook.updated_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              end
              if Review.exists?(:notebook_id => notebook.id)
                Review.where(:notebook_id => notebook.id).each do |review|
                  if review.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && review.updated_at + 3.days > Time.now)
                    sendEmail = true
                    throw :sendEmail
                  end
                end
              end
            end
            Tag.where(:tag => Tag.find(element.sub_id).tag).each do |tag|
              if (Time.now.strftime("%A") == "Monday" && tag.created_at + 3.days > Time.now) || tag.created_at + 1.days > Time.now
                sendEmail = true
                throw :sendEmail
              end
            end
          end
          notebook_subscriptions.each do |element|
            if Notebook.find(element.sub_id).public == false
              next
            end
            if Notebook.find(element.sub_id).created_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && Notebook.find(element.sub_id).created_at + 3.days > Time.now)
              sendEmail = true
              throw :sendEmail
            elsif Notebook.find(element.sub_id).updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && Notebook.find(element.sub_id).updated_at + 3.days > Time.now)
              sendEmail = true
              throw :sendEmail
            end
            if Review.exists?(:notebook_id => element.sub_id)
              Review.where(:notebook_id => element.sub_id).each do |review|
                if review.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && review.updated_at + 3.days > Time.now)
                  sendEmail = true
                  throw :sendEmail
                end
              end
            end
            sql_statement = "thread_id in (select commontator_threads.id from commontator_threads where commontator_threads.commontable_id=#{element.sub_id})"
            Commontator::Comment.where(sql_statement).each do |comment|
              if comment.updated_at + 1.days > Time.now || (Time.now.strftime("%A") == "Monday" && comment.updated_at + 3.days > Time.now)
                sendEmail = true
                throw :sendEmail
              end
            end
          end
        end
        if sendEmail == true
          log("Sending subscription email to user: #{user.first_name} #{user.last_name} at #{user.email}")
          begin
            SubscriptionMailer.daily_subscription_email(user.id,ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST']).deliver
          rescue EOFError => e
            log("EOFError: can't send email to user due to error. Full message: \"#{e}\" encountered for user: #{user.first_name} #{user.last_name}. Email recipient: #{user.email}, email sender host: #{ENV['EMAIL_DEFAULT_URL_OPTIONS_HOST']}. User has #{user_subscriptions.count} user subs, #{group_subscriptions.count} group subs, #{tag_subscriptions.count} tag subs, #{notebook_subscriptions.count} notebook subs. More investigation is required. Continuing . . .")
            next
          rescue => e
            log("Error: Stopping daily_subscription_email job. Full message: \"#{e}\"")
          end
        end
      end
    end
  end
end
