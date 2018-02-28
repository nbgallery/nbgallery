# Identities table
# rubocop: disable Rails/CreateTableWithTimestamps
class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.string :uid
      t.string :provider
      t.references :user
    end
    add_index :identities, :user_id

    #Migrate all existing users over and create identities for them.
    #Then remove the columns
    User.all.each do |u|
      Identity.new(uid: u.uid, provider: u.provider, user_id: u.id)
    end
    remove_column :users, :uid, :string
    remove_column :users, :provider, :string
  end
end
# rubocop: enable Rails/CreateTableWithTimestamps
