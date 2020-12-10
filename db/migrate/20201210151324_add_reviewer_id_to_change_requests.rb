class AddReviewerIdToChangeRequests < ActiveRecord::Migration
  def change
    add_column :change_requests, :reviewer_id, :integer, foreign_key: true
  end
end
