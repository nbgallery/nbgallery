class AddParentUuidToNotebooks < ActiveRecord::Migration[6.1]
  def up
    add_column :notebooks, :parent_uuid, :string, null: true
    add_index :notebooks, :parent_uuid
  end
  def down
    remove_column :notebooks, :parent_uuid
  end
end
