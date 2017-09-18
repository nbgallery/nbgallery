# Migration to convert notebooks table to UTF-8
class NotebooksUtf8 < ActiveRecord::Migration
  def up
    Notebook.connection.execute('ALTER TABLE notebooks CONVERT TO CHARACTER SET utf8')
  end
end
