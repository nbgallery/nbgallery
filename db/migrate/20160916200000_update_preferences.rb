# Migration to create preferences table
class UpdatePreferences < ActiveRecord::Migration[4.2]
  def change
    remove_column :preferences, :service, :string
    remove_column :preferences, :url, :string
    add_column :preferences, :auto_close_brackets, :boolean, after: :user_id
    add_column :preferences, :smart_indent, :boolean, after: :user_id
  end
end
