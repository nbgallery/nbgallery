# Gitlab client wrapped in Retryable
class RetryableGitlab
  def initialize(client, path)
    @client = client
    Retryable.retryable(
      tries: 3,
      sleep: ->(n) {2**n},
      on: Gitlab::Error::Parsing
    ) do |_retries, _exception|
      #puts "RETRY #{retries} for :project due to #{exception.class}: #{exception}" if retries > 0
      @project = @client.project(path).id
    end
  end

  def method_missing(method, *args, &block)
    super unless @client.respond_to?(method)
    info = Retryable.retryable(
      tries: 3,
      sleep: ->(n) {2**n},
      on: StandardError,
      not: NoMethodError
    ) do |_retries, _exception|
      #puts "RETRY #{retries} for :#{method} due to #{exception.class}: #{exception}" if retries > 0
      @client.send(method, @project, *args, &block)
    end
    # If creating or editing a file, inject the commit id into the return hash
    if %i[create_file edit_file].include? method
      info = Retryable.retryable(
        tries: 3,
        sleep: ->(n) {2**n},
        on: StandardError,
        not: NoMethodError
      ) do |_retries, _exception|
        #puts "RETRY #{retries} for :#{method} due to #{exception.class}: #{exception}" if retries > 0
        file_info = @client.get(
          "/projects/#{@project}/repository/files?file_path=#{info.file_path}&ref=#{info.branch_name}"
        )
        Gitlab::ObjectifiedHash.new info.to_h.merge(commit_id: file_info.commit_id)
      end
    end
    info
  end

  private

  def respond_to_missing?(name, _include_private=false)
    @client.respond_to?(name)
  end
end
