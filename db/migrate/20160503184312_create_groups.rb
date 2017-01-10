# Migration to create groups table
class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :gid, index: { unique: true }, null: false
      t.string :name, null: false
      t.text :description
      t.string :url

      t.integer :landing_id
      t.foreign_key :notebooks, column: :landing_id, on_update: :cascade, on_delete: :nullify

      t.timestamps null: false
    end
  end
end
