class CreateResources < ActiveRecord::Migration[4.2]
  def change
    create_table :resources do |t|
      t.string :href
      t.string :title
      t.references :notebook, index: true, foreign_key: true
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
