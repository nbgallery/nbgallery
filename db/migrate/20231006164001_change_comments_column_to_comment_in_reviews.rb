class ChangeCommentsColumnToCommentInReviews < ActiveRecord::Migration[6.1]
  def change
    rename_column :reviews, :comments, :comment
  end
end
