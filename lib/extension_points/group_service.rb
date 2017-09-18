# Interface for using an external group service
class GroupService
  # rubocop: disable Lint/UnusedMethodArgument

  # Update user/group membership from external service
  def self.refresh_user(user, force=false)
  end

  # Update group info from external service
  def self.refresh_group(group, force=false)
  end

  # Update all group info
  def self.refresh_all_groups
  end

  # rubocop: enable Lint/UnusedMethodArgument
end
