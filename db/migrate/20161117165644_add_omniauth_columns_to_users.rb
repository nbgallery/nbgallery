# Omniauth login support
class AddOmniauthColumnsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :provider, :string
    add_column :users, :uid, :string
  end
end
