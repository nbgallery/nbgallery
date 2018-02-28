# Create code_cells table

# rubocop: disable Rails/CreateTableWithTimestamps
# timestamps fixed in later migration
class CreateCodeCells < ActiveRecord::Migration
  def change
    create_table :code_cells do |t|
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.integer :cell_number
      t.string :md5
      t.text :ssdeep
    end
    add_index :code_cells, :md5
  end
end
# rubocop: enable Rails/CreateTableWithTimestamps
