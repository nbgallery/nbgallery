class AddCommitMessageToChangeRequests < ActiveRecord::Migration
  def change
    add_column :change_requests, :commit_message, :string
  end
end
