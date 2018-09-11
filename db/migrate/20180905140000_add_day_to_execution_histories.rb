# Add day (without time) to execution histories.
# This fixes a race condition to ensure only one record per (user, notebook, day).
class AddDayToExecutionHistories < ActiveRecord::Migration
  def change
    # 1. Fix previous insertion bug that allowed multiple entries per (user, nb, day)
    # Identify (user, nb, day) tuples with multiple records
    bad = ExecutionHistory
      .select('user_id, notebook_id, DATE(created_at) AS day, COUNT(*) AS c')
      .group('user_id, notebook_id, day')
      .having('c > 1')
    # Merge records and delete the extras
    bad.each do |e|
      records = ExecutionHistory
        .where(user_id: e.user_id, notebook_id: e.notebook_id)
        .where('DATE(created_at) = ?', e.day)
      first = records[0]
      records[1..-1].each do |rec|
        first.known_cell ||= rec.known_cell
        first.unknown_cell ||= rec.unknown_cell
        first.created_at = [first.created_at, rec.created_at].min
        first.updated_at = [first.updated_at, rec.updated_at].max
        rec.destroy
      end
      first.save
    end

    # 2. Add day column and unique index for (user, nb, day)
    change_table :execution_histories, bulk: true do |t|
      t.date :day
      t.index :day
      t.index %i[user_id notebook_id day], unique: true
    end

    # 3. Populate day column from created_at for existing entries
    ExecutionHistory.update_all('day = DATE(created_at)') # rubocop: disable Rails/SkipsModelValidations
  end
end
