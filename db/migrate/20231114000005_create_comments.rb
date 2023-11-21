class CreateComments < ActiveRecord::Migration[6.1]
    def self.up
      create_table :comments do |t|

        t.integer :user_id
        t.foreign_key :users, on_update: :cascade, on_delete: :nullify
        t.integer :notebook_id, null: false
        t.foreign_key :notebooks, on_update: :cascade, on_delete: :cascade
        t.boolean :private, null: false
        t.integer :parent_comment_id
        t.boolean :ran
        t.boolean :worked
        t.text :comment, limit: 1000

        t.timestamps null: false
      end
    end

    def self.down
      raise IrreversibleMigration
    end
  end
  