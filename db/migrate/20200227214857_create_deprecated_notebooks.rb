class CreateDeprecatedNotebooks < ActiveRecord::Migration
  def change
    create_table :deprecated_notebooks do |t|
      t.integer :notebook_id
      t.integer :deprecater_user_id
      t.boolean :disable_usage
      t.string :reasoning
      t.text :alternate_notebook_ids, array: true

      t.timestamps null: false
    end
  end
end
