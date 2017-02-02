# Add notebook health to summary
class AddHealthToNotebookSummary < ActiveRecord::Migration
  def change
    add_column :notebook_summaries, :health, :float
    add_index :notebook_summaries, :health
  end
end
