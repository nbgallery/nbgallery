# Gitlab interface for remote storage
class RemoteStorage
  class << self
    # Store a new file.
    def create_file(filename, content, options={})
      return nil unless enabled?
      branch = options[:branch] || 'master'
      message = options[:message] || 'create file'
      gallery_client(options).create_file(filename, branch, content, message).commit_id
    end

    # Update an existing file.
    def edit_file(filename, content, options={})
      return nil unless enabled?
      branch = options[:branch] || 'master'
      message = options[:message] || 'edit file'
      gallery_client(options).edit_file(filename, branch, content, message).commit_id
    end

    # Remove an existing file.
    def remove_file(filename, options={})
      return nil unless enabled?
      branch = options[:branch] || 'master'
      message = options[:message] || 'remove file'
      gallery_client(options).remove_file(filename, branch, message).commit_id
    end

    # Retrieve a file.
    def get_file(filename, options={})
      return nil unless enabled?
      branch = options[:branch] || 'master'
      gallery_client(options).file_contents(filename, branch)
    end

    protected

    # Gitlab enabled by setting all necessary ENV vars?
    def enabled?
      ENV['GITLAB_API_ENDPOINT'] &&
        ENV['GITLAB_API_PRIVATE_TOKEN'] &&
        ENV['GITLAB_PUBLIC_REPO'] &&
        ENV['GITLAB_PRIVATE_REPO']
    end

    # Use the public notebook repo?
    def public?(options)
      !(options[:public] == false || options[:public] == :private)
    end

    # Client to connect to gitlab
    def gitlab_client
      return nil unless enabled?
      Gitlab.client(
        endpoint: ENV['GITLAB_API_ENDPOINT'],
        private_token: ENV['GITLAB_API_PRIVATE_TOKEN']
      )
    end

    # Client to connect to public or private notebook repo
    def gallery_client(options)
      return nil unless enabled?
      client = gitlab_client
      if public?(options)
        RetryableGitlab.new(client, ENV['GITLAB_PUBLIC_REPO'])
      else
        RetryableGitlab.new(client, ENV['GITLAB_PRIVATE_REPO'])
      end
    end
  end
end
