class AddRowNumbersColumnToUserPreferences < ActiveRecord::Migration
  def up
    add_column :user_preferences, :disable_row_numbers, :boolean, default: false
  end

  def down
    remove_column :user_preferences, :disable_row_numbers
  end
end
