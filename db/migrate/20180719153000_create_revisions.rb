# Create notebook revision table
class CreateRevisions < ActiveRecord::Migration
  def change
    create_table :revisions do |t|
      t.references :user
      t.foreign_key :users, on_delete: :nullify, on_update: :cascade
      t.references :notebook, null: false
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.boolean :public
      t.string :commit_id
      t.string :revtype
      t.timestamps null: false
    end
  end
end
