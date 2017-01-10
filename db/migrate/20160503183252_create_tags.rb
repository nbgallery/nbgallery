# Migration to create tags table
class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.references :user
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.string :tag, index: true, null: false
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade

      t.timestamps null: false
    end
  end
end
