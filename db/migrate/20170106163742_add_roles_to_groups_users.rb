# Add ownership role info to group-user join table
class AddRolesToGroupsUsers < ActiveRecord::Migration
  def change
    add_column :groups_users, :creator, :bool
    add_column :groups_users, :owner, :bool
    add_column :groups_users, :editor, :bool

    drop_table :group_owners # rubocop: disable Rails/ReversibleMigration
  end
end
