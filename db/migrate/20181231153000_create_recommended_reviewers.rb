# Migration to create recommended reviewers table
class CreateRecommendedReviewers < ActiveRecord::Migration
  def change
    create_table :recommended_reviewers do |t|
      t.references :review, null: false
      t.foreign_key :reviews, on_delete: :cascade, on_update: :cascade

      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade

      t.float :score

      t.timestamps null: false
    end
  end
end
