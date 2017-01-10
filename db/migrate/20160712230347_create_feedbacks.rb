# Migration for feedback table
class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.references :user
      t.foreign_key :users, on_update: :cascade, on_delete: :nullify
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_update: :cascade, on_delete: :cascade
      t.boolean :ran
      t.boolean :worked
      t.text :broken_feedback
      t.text :general_feedback

      t.timestamps null: false
    end
  end
end
