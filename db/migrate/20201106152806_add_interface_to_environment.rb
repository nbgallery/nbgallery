class AddInterfaceToEnvironment < ActiveRecord::Migration[4.2]
  def change
    add_column :environments, :user_interface, :string
  end
end
