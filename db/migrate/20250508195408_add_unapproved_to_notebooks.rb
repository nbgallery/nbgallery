class AddUnapprovedToNotebooks < ActiveRecord::Migration[6.1]
  def change
    add_column :notebooks, :unapproved, :boolean, default: false
  end
end
