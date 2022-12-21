# Add fields to preferences table
class AddEditorPreferences < ActiveRecord::Migration[4.2]
  def change
    add_column :preferences, :tab_size, :integer, after: :auto_close_brackets
    add_column :preferences, :indent_unit, :integer, after: :auto_close_brackets
    add_column :preferences, :easy_buttons, :boolean, after: :auto_close_brackets
  end
end
