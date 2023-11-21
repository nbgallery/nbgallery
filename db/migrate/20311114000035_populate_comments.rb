class PopulateComments < ActiveRecord::Migration[6.1]
    def self.up

      # Add all Feedback table rows to new generic Comments table
      Feedback.all.each do |feedback|
        comment = ""
        if feedback.broken_feedback != nil && feedback.broken_feedback.strip.length > 0
            comment += "Broken Feedback: " + feedback.broken_feedback.strip
        end
        if feedback.general_feedback != nil && feedback.general_feedback.strip.length > 0
            if comment.length > 0 && comment[-1] != "."
                comment += "."
            end
            comment += "General Feedback: " + feedback.general_feedback
        end
        if comment.length > 1000
          comment = comment[0..996] + "..."
        end
        Comment.create(user_id: feedback.user_id, notebook_id: feedback.notebook_id, private: true, parent_comment_id: nil, ran: feedback.ran, worked: feedback.worked, comment: comment, created_at: feedback.created_at, updated_at: feedback.updated_at)
      end

      Commontator::Comment.all.each do |comment|
        message = ""
        message = comment.body
        if message.length > 1000
          message = message[0..996] + "..."
        end
        Comment.create(user_id: comment.creator_id, notebook_id: Commontator::Thread.find(comment.thread_id).commontable_id, private: false, parent_comment_id: nil, ran: nil, worked: nil, comment: message, created_at: comment.created_at, updated_at: comment.updated_at)
      end
      #execute "INSERT INTO `comments` (users, notebook, field_3) SELECT (users, field_2, field_3) FROM `feedbacks`;"

      # DO NOT UNCOMMENT until fully satisfied with combined table and functionality
      #drop_table :commontator_comments
      #drop_table :commontator_subscriptions
      #drop_table :commontator_threads
      #drop_table :feedbacks
    end

    def self.down
      raise IrreversibleMigration
    end
  end
  