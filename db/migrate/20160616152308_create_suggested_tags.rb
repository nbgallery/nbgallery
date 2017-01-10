# Migration to create tag suggestion table
class CreateSuggestedTags < ActiveRecord::Migration
  def change
    create_table :suggested_tags do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.string :tag

      t.timestamps null: false
    end
  end
end
