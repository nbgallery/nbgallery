# Migration to create clickstream table
class CreateClicks < ActiveRecord::Migration
  def change
    create_table :clicks do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.string :org, index: true
      t.string :action, index: true, null: false
      t.references :notebook
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.string :tracking

      t.timestamps null: false
    end
  end
end
