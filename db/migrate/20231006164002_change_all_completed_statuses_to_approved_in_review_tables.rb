class ChangeAllCompletedStatusesToApprovedInReviewTables < ActiveRecord::Migration[6.1]
  def change
    execute('UPDATE reviews SET status = "approved" where status = "completed"')
  end
end
