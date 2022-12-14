class AddPrimaryToGroupsUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :groups_users, :id, :primary_key
  end
end
