class AddPrimaryToGroupsUsers < ActiveRecord::Migration
  def change
    add_column :groups_users, :id, :primary_key
  end
end
