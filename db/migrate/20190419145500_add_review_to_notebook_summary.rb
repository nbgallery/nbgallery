# Add review status to summary
class AddReviewToNotebookSummary < ActiveRecord::Migration
  def change
    change_table :notebook_summaries, bulk: true do |t|
      t.float :review
      t.index :review
      t.string :review_description
    end
  end
end
