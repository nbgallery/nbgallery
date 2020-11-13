class ChangeReasoningToBeTextInDeprecatedNotebooks < ActiveRecord::Migration
  def up
    change_column :deprecated_notebooks, :reasoning, :text
  end

  def down
    change_column :deprecated_notebooks, :reasoning, :string
  end
end
