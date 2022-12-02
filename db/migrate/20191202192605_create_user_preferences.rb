class CreateUserPreferences < ActiveRecord::Migration[4.2]
  def change
    create_table :user_preferences do |t|
      t.integer :user_id
      t.string :theme
      t.integer :timezone, limit: 4
      t.boolean :high_contrast
      t.boolean :larger_text
      t.boolean :ultimate_accessibility_mode

      t.timestamps null: false
    end
  end
end
