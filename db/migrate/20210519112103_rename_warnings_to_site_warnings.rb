class RenameWarningsToSiteWarnings < ActiveRecord::Migration
  def self.up
    rename_table :warnings, :site_warnings
  end

  def self.down
    rename_table :site_warnings, :warnings
  end
end
