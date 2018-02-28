# Create execution log table

# rubocop: disable Rails/CreateTableWithTimestamps
# timestamps fixed in later migration
class CreateExecutions < ActiveRecord::Migration
  def change
    create_table :executions do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.references :code_cell, null: false
      t.foreign_key :code_cells, on_delete: :cascade, on_update: :cascade
      t.boolean :success
      t.float :runtime
    end
  end
end
# rubocop: enable Rails/CreateTableWithTimestamps
