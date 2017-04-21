# Migration to create users <-> notebooks join table for stars
class CreateStarJoinTable < ActiveRecord::Migration
  def change
    create_join_table :users, :notebooks, table_name: 'stars' do |t|
      # t.index [:user_id, :notebook_id]
      t.index %i[notebook_id user_id], unique: true
      t.foreign_key :notebooks, on_delete: :cascade, on_update: :cascade
      t.foreign_key :users, on_delete: :cascade, on_update: :cascade
    end
  end
end
