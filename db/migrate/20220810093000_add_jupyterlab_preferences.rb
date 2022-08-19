# Migration to create preferences table
class AddJupyterlabPreferences < ActiveRecord::Migration
  def change
    add_column :preferences, :lab_preferences, :text
  end
end
