# Preview all emails at http://localhost:3000/rails/mailers/notebook_mailer
class NotebookMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/notebook_mailer/share
  def share
    NotebookMailer.share(Notebook.first,User.first,[User.first.email],"You gotta check this notebook out!","http://localhost:3000")
  end

  # Prview this email at http://localhost:3000/rails/mailers/notebook_mailer/share_non_member
  def share_non_member
    NotebookMailer.share_non_member(Notebook.first,User.first,[User.first.email],"You gotta check this notebook out!","http://localhost:3000")
  end

  # Preview this email at http://localhost:3000/rails/mailers/notebook_mailer/feedback
  def feedback
    NotebookMailer.feedback(Feedback.first, "http://localhost:3000")
  end

  # Preview this email at http://localhost:3000/rails/mailers/notebook_mailer/recommended_reviewer_added
  def recommended_reviewer_added
    NotebookMailer.recommended_reviewer_added(Review.first, User.first, "https://localhost:3000")
  end
end
