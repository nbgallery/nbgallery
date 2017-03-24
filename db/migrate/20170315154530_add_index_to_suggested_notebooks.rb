# Add index to suggested_notebooks.reason
class AddIndexToSuggestedNotebooks < ActiveRecord::Migration
  def change
    add_index :suggested_notebooks, :reason, length: 32
  end
end
