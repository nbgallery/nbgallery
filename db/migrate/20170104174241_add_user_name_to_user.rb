# Add username column to user table
class AddUserNameToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :user_name, :string
    add_index :users, :user_name
  end
end
