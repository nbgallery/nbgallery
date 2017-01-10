# Migration to create notebook suggestion table
class CreateSuggestedNotebooks < ActiveRecord::Migration
  def change
    create_table :suggested_notebooks do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.text :reason
      t.float :score

      t.timestamps null: false
    end
  end
end
