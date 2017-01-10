# Migration to convert keyword table to UTF-8
class KeywordsUtf8 < ActiveRecord::Migration
  def up
    Keyword.connection.execute('ALTER TABLE keywords CONVERT TO CHARACTER SET utf8')
  end
end
