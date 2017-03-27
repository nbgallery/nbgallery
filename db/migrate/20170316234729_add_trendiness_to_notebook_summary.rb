# Add notebook trendiness to summary
class AddTrendinessToNotebookSummary < ActiveRecord::Migration
  def change
    add_column :notebook_summaries, :trendiness, :float
    add_index :notebook_summaries, :trendiness
  end
end
