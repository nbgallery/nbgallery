# Add timestamps to code cell model
class AddTimestampsToCodeCells < ActiveRecord::Migration
  def change
    add_timestamps :code_cells
  end
end
