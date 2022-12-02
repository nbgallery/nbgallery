# Add timestamps to code cell model
class AddTimestampsToCodeCells < ActiveRecord::Migration[4.2]
  def change
    add_timestamps :code_cells
  end
end
