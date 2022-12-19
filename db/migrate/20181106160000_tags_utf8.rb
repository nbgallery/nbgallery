# Migration to convert tags table to UTF-8
class TagsUtf8 < ActiveRecord::Migration[4.2]
  def up
    Tag.connection.execute('ALTER TABLE tags CONVERT TO CHARACTER SET utf8')
  end
end
