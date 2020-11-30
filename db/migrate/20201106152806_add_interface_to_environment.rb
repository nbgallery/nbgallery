class AddInterfaceToEnvironment < ActiveRecord::Migration
  def change
    add_column :environments, :user_interface, :string
  end
end
