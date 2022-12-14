# Add polymorphic source column to suggested_notebooks table
class AddSourceToSuggestedNotebooks < ActiveRecord::Migration[4.2]
  def change
    add_reference :suggested_notebooks, :source, polymorphic: true, index: true
  end
end
