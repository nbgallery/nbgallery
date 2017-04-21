# Migration for notebook similarity score table
class CreateNotebookSimilarities < ActiveRecord::Migration
  def change
    create_table :notebook_similarities do |t|
      t.integer :notebook_id, null: false
      t.integer :other_notebook_id, null: false
      t.index %i[notebook_id other_notebook_id], unique: true
      t.float :score

      t.timestamps null: false
    end
    add_foreign_key(
      :notebook_similarities,
      :notebooks,
      column: :notebook_id,
      on_delete: :cascade,
      on_update: :cascade
    )
    add_foreign_key(
      :notebook_similarities,
      :notebooks,
      column: :other_notebook_id,
      on_delete: :cascade,
      on_update: :cascade
    )
  end
end
