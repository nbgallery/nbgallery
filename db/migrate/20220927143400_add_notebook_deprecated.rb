# Migration to add deprecated field to notebooks table
class AddNotebookDeprecated < ActiveRecord::Migration
  def change
    add_column :notebooks, :deprecated, :boolean, default: false
    add_index :notebooks, :deprecated
    execute "UPDATE notebooks set deprecated=1 where id in (select notebook_id from deprecated_notebooks)"
  end
end
