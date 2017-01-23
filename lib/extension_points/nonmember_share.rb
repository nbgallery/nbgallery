# Stub to handle attempts to share with non-members
class NonmemberShare
  def self.share(_notebook, _owner, _names, _message, _url)
    # No-op by default

    # If non-members are specified as email addresses, you could do this:
    # NotebookMailer.share_non_member(notebook, owner, names, message, url).deliver_later
  end
end
