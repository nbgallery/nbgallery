json.extract!(
    revision,
    :id,
    :revtype,
    :commit_message,
    :updated_at
  )
  if revision.user.nil?
    json.user "Unknown"
  else
    json.user = revision.user.user_name
  end
  json.url = notebook_revision_url(revision.notebook,revision)
  