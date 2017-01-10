# Migration to create notebooks table
class CreateNotebooks < ActiveRecord::Migration
  def change
    create_table :notebooks do |t|
      t.string :uuid, index: { unique: true }, null: false
      t.string :title, index: true, null: false
      t.text :description, null: false
      t.boolean :public, null: false
      t.string :lang, index: true
      t.string :lang_version
      t.string :commit_id
      t.datetime :content_updated_at
      t.references :owner, polymorphic: true, index: true
      t.integer :creator_id
      t.integer :updater_id

      t.timestamps null: false
    end
    # Cannot add these inside the block above -- only one gets created.
    # (Maybe because they're both on the same parent table?)
    add_foreign_key :notebooks, :users, column: :creator_id, on_delete: :nullify, on_update: :cascade
    add_foreign_key :notebooks, :users, column: :updater_id, on_delete: :nullify, on_update: :cascade
  end
end
