# Migration to create notebook_summaries table
class CreateNotebookSummaries < ActiveRecord::Migration
  def change
    create_table :notebook_summaries do |t|
      t.references :notebook, null: false, index: { unique: true }
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.integer :views, default: 0
      t.integer :unique_views, default: 0
      t.integer :downloads, default: 0
      t.integer :unique_downloads, default: 0
      t.integer :runs, default: 0
      t.integer :unique_runs, default: 0
      t.integer :stars, default: 0

      t.timestamps null: false
    end
  end
end
