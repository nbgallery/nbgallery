# Stub interface for remote storage service
class RemoteStorage
  class << self
    # Store a new file.  Return a commit id of some sort.
    def create_file(filename, content, options={})
    end

    # Update an existing file.  Return a commit id of some sort.
    def edit_file(filename, content, options={})
    end

    # Remove an existing file.  Return a commit id of some sort.
    def remove_file(filename, options={})
    end

    # Retrieve a file.  Return the content.
    def get_file(filename, options={})
    end
  end
end
