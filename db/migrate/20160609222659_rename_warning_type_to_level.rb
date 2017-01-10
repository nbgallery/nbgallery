# Rename column because 'type' is reserved by rails
class RenameWarningTypeToLevel < ActiveRecord::Migration
  def change
    change_table :warnings do |t|
      t.rename :type, :level
    end
  end
end
