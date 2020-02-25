class CreateDeprecatedNotebooks < ActiveRecord::Migration
  def change
    create_table :deprecated_notebooks do |t|
      t.integer :notebook_id
      t.boolean :frozen
      t.string :reasoning
      t.text :alternate_notebook_ids, array: true

      t.timestamps null: false
    end
  end
end
