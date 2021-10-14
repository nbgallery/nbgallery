class AddFullCellsColumnToUserPreferences < ActiveRecord::Migration
  def up
    add_column :user_preferences, :full_cells, :boolean, default: nil
  end

  def down
    remove_column :user_preferences, :full_cells
  end
end
