class ChangeTimezoneToBeStringInUserPreferences < ActiveRecord::Migration
  def up
    change_column :user_preferences, :timezone, :string
  end

  def down
    change_column :user_preferences, :timezone, :integer
  end
end
