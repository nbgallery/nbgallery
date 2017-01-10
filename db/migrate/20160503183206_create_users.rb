# Migration to create users table
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email, index: { unique: true }
      t.string :password
      t.string :first_name
      t.string :last_name
      t.string :org
      t.boolean :admin

      t.timestamps null: false
    end
  end
end
