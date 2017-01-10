# Migration to create group suggestion table
class CreateSuggestedGroups < ActiveRecord::Migration
  def change
    create_table :suggested_groups do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.references :group, null: false
      t.foreign_key :groups, on_delete: :cascade, on_update: :cascade

      t.timestamps null: false
    end
  end
end
