# Migration to create change_requests table
class CreateChangeRequests < ActiveRecord::Migration
  def change
    create_table :change_requests do |t|
      t.string :reqid, index: { unique: true }, null: false
      t.integer :requestor_id, null: false
      t.foreign_key :users, column: :requestor_id, on_delete: :cascade, on_update: :cascade
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.string :status, index: true, null: false
      t.text :requestor_comment
      t.text :owner_comment

      t.timestamps null: false
    end
  end
end
