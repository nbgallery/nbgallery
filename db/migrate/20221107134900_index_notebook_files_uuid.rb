# Migration to add deprecated field to notebooks table
class IndexNotebookFilesUuid < ActiveRecord::Migration[4.2]
  def change
    add_index :notebook_files, :uuid, length: 190
  end
end
