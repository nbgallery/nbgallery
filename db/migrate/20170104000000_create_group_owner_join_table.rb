# Migration to create users <-> groups join table for group ownership
class CreateGroupOwnerJoinTable < ActiveRecord::Migration
  def change
    create_join_table :users, :groups, table_name: 'group_owners' do |t|
      # t.index [:user_id, :group_id]
      t.index %i[group_id user_id], unique: true
      t.foreign_key :groups, on_delete: :cascade, on_update: :cascade
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
    end
  end
end
