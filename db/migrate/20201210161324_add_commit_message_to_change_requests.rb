class AddCommitMessageToChangeRequests < ActiveRecord::Migration
  def change
    add_column :change_requests, :commit_message, :string
    add_column :change_requests, :reviewer_id, :integer, foreign_key: true
  end
end
