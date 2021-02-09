class CreateNotebookFiles < ActiveRecord::Migration
  def change
    create_table :notebook_storages do |t|
      t.text :content, null:false
      t.string :save_type, null: false
      t.references :revision, index: true, foreign_key: true
      t.references :change_requests, index: true, foreign_key: true
      t.references :stages, index: true, foreign_key: true
      t.references :notebook, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
