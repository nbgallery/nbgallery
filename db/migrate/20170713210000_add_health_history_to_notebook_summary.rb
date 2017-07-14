# Add health history to summary
class AddHealthHistoryToNotebookSummary < ActiveRecord::Migration
  def change
    add_column :notebook_summaries, :previous_health, :float
    add_column :notebook_summaries, :health_description, :string
  end
end
