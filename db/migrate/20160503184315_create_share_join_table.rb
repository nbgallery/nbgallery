# Migration to create users <-> notebooks join table for shares
class CreateShareJoinTable < ActiveRecord::Migration
  def change
    create_join_table :notebooks, :users, table_name: 'shares' do |t|
      # t.index [:notebook_id, :user_id]
      t.index %i[user_id notebook_id], unique: true
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
    end
  end
end
