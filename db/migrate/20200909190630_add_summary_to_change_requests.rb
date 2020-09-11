class AddSummaryToChangeRequests < ActiveRecord::Migration
  def change
    add_column :change_requests, :summary, :string
  end
end
