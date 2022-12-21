# Add timestamps to execution log
class AddTimestampsToExecutions < ActiveRecord::Migration[4.2]
  def change
    add_timestamps :executions
  end
end
