class AddSummaryToRevisions < ActiveRecord::Migration
  def change
    add_column :revisions, :summary, :string
  end
end
