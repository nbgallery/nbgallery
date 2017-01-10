# Stub to handle attempts to share with non-members
class NonmemberShare
  def self.share(notebook, owner, emails, message, url)
    NotebookMailer.share_non_member(notebook, owner, emails, message, url).deliver_later
  end
end
