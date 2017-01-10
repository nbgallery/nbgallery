# Migration to create notebook keyword table
class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.string :keyword
      t.float :tfidf
      t.float :tf
      t.float :idf

      t.timestamps null: false
    end
  end
end
