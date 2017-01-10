# Migration to create warnings table
class CreateWarnings < ActiveRecord::Migration
  def change
    create_table :warnings do |t|
      t.references :user
      t.foreign_key :users, on_delete: :nullify, on_update: :cascade
      t.string :type, null: false
      t.text :message, null: false
      t.datetime :expires

      t.timestamps null: false
    end
  end
end
