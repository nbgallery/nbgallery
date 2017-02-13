# Add timestamps to execution log
class AddTimestampsToExecutions < ActiveRecord::Migration
  def change
    add_timestamps :executions
  end
end
