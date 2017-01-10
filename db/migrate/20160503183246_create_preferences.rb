# Migration to create preferences table
class CreatePreferences < ActiveRecord::Migration
  def change
    create_table :preferences do |t|
      t.references :user
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.string :service
      t.string :url

      t.timestamps null: false
    end
  end
end
