class AddApproverIdToChangeRequests < ActiveRecord::Migration
  def change
    add_column :change_requests, :approver_id, :integer, foreign_key: true
  end
end
