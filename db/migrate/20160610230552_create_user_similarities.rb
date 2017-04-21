# Migration for user similarity score table
class CreateUserSimilarities < ActiveRecord::Migration
  def change
    create_table :user_similarities do |t|
      t.integer :user_id, null: false
      t.integer :other_user_id, null: false
      t.index %i[user_id other_user_id], unique: true
      t.float :score

      t.timestamps null: false
    end
    add_foreign_key(
      :user_similarities,
      :users,
      column: :user_id,
      on_delete: :cascade,
      on_update: :cascade
    )
    add_foreign_key(
      :user_similarities,
      :users,
      column: :other_user_id,
      on_delete: :cascade,
      on_update: :cascade
    )
  end
end
