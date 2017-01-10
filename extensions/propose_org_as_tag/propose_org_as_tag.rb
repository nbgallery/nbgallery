# Extension to propose the user's organization as a tag
module ProposeOrgAsTag
  def propose_tags_from_user_org(user)
    Set.new([user.org])
  end
end
