# Migration to create environments table
class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.references :user
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.string :name
      t.string :url
      t.boolean :default

      t.timestamps null: false
    end
  end
end
