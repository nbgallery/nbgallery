# Migration to convert groups table to UTF-8
class GroupsUtf8 < ActiveRecord::Migration
  def up
    Group.connection.execute('ALTER TABLE groups CONVERT TO CHARACTER SET utf8')
  end
end
