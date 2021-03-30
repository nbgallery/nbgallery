class CreateNotebookFiles < ActiveRecord::Migration
  def change
    create_table :notebook_files, options: "DEFAULT CHARSET=utf8mb4" do |t|
      t.text :content, null:false, :limit => 16000000
      t.string :save_type, null: false
      t.string :uuid, null: false
      t.references :revision, foreign_key: true
      t.references :change_request, foreign_key: true
      t.references :stage, foreign_key: true
      t.references :notebook, foreign_key: true
      t.timestamps null: false
    end
  end
end
