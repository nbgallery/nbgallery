# Migration to create preferences table
class AddJupyterlabPreferences < ActiveRecord::Migration[4.2]
  def change
    add_column :preferences, :lab_preferences, :text
  end
end
