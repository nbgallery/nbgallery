# Add notebook trendiness to summary
class AddTrendinessToNotebookSummary < ActiveRecord::Migration[4.2]
  def change
    add_column :notebook_summaries, :trendiness, :float
    add_index :notebook_summaries, :trendiness
  end
end
