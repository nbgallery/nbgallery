# Create execution history table
class CreateExecutionHistories < ActiveRecord::Migration
  def change
    create_table :execution_histories do |t|
      t.references :user, null: false
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.boolean :known_cell
      t.boolean :unknown_cell
      t.timestamps null: false
    end
  end
end
