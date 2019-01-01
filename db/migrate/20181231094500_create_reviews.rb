# Migration to create reviews table
class CreateReviews < ActiveRecord::Migration
  def change
    create_table :reviews do |t|
      # Notebook that was reviewed
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade

      # Link to specific revision that was reviewed.
      # This can be null because revision tracking might be turned off.
      t.references :revision, null: true
      t.foreign_key :revisions, on_delete: :cascade, on_update: :cascade

      # Reviewer.  Can be null if not reviewed yet.
      # Keep the review even if the reviewer is deleted.
      t.integer :reviewer_id, null: true
      t.foreign_key :users, column: :reviewer_id, on_delete: :nullify, on_update: :nullify

      # Review types: technical, functional, compliance
      t.string :revtype, index: true, null: false

      # Status: queued, claimed, completed
      t.string :status, index: true, null: false

      # Reviewer comments or reason for being queued
      t.text :comments

      t.timestamps null: false
    end
  end
end
