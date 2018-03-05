# Migration to create notebook_dailies table
class CreateNotebookDailies < ActiveRecord::Migration
  def change
    create_table :notebook_dailies do |t|
      t.references :notebook, null: false, index: true
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.date :day, index: true
      t.integer :unique_users, default: 0
      t.integer :unique_executors, default: 0
      t.float :daily_score, default: 0

      t.timestamps null: false
    end
  end
end
