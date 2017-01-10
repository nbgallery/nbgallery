# Migration to create stages table
class CreateStages < ActiveRecord::Migration
  def change
    create_table :stages do |t|
      t.string :uuid, index: { unique: true }, null: false
      t.references :user, null: false
      t.foreign_key :users, on_update: :cascade, on_delete: :cascade

      t.timestamps null: false
    end
  end
end
