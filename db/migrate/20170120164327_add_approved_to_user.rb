# Add approval column to user table
class AddApprovedToUser < ActiveRecord::Migration
  def change
    add_column :users, :approved, :boolean
    add_index :users, :approved
  end
end
