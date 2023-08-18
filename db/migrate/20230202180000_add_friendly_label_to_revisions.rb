class AddFriendlyLabelToRevisions < ActiveRecord::Migration[6.0]
  def up
    return unless table_exists?(:revisions)

    unless column_exists?(:revisions, :friendly_label)
      add_column :revisions, :friendly_label, :string

      change_column :revisions, :friendly_label, :string, limit: 16, null: true
    end
  end

  def down
    return unless table_exists?(:revisions)

    remove_column :revisions, :friendly_label
  end
end
