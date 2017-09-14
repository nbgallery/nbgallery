# Migration to create user_summaries table
class CreateUserSummaries < ActiveRecord::Migration
  def change
    create_table :user_summaries do |t|
      t.references :user, null: false, index: { unique: true }
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.float :user_rep_raw, default: 0
      t.float :user_rep_pct, default: 0
      t.float :author_rep_raw, default: 0
      t.float :author_rep_pct, default: 0

      t.timestamps null: false
    end
  end
end
