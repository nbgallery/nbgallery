class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :user_id, null: false, foreign_key: true, on_delete: :nullify, on_update: :nullify
      t.string :sub_type, null: false
      t.integer :sub_id, null: false
      
      t.timestamps null: false

    end
  end
end
