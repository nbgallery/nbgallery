# Rename column because 'type' is reserved by rails
class RenameWarningTypeToLevel < ActiveRecord::Migration
  def change
    rename_column :warnings, :type, :level
  end
end
