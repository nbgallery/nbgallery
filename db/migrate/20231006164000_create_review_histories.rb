class CreateReviewHistories < ActiveRecord::Migration[6.1]
  def change
    create_table :review_histories do |t|
      t.integer :review_id, null:false
      t.foreign_key :reviews, column: :review_id, on_delete: :cascade, on_update: :cascade
      t.integer :user_id
      t.foreign_key :users, column: :user_id, on_delete: :nullify, on_update: :nullify
      t.string :action, null:false
      t.integer :reviewer_id
      t.text :comment

      t.timestamps
    end
  end
end
