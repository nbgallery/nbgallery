class AddCommitMessageToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :commit_message, :string
  end
end
