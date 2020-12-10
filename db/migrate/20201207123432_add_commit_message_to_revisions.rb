class AddCommitMessageToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :commit_message, :string
    add_column :revisions, :change_request_id, :integer, foreign_key: true
  end
end
