class AddNotebookVerified < ActiveRecord::Migration[6.1]
  def change
    add_column :notebooks, :verified, :boolean, default: false
    add_index :notebooks, :verified
    execute("UPDATE notebooks SET verified = 0")
  end
end
