json.extract!(
  notebook,
  :uuid,
  :title,
  :description,
  :public,
  :lang,
  :lang_version,
  :commit_id,
  :content_updated_at
)
tags = []
notebook.tags.each do |tag|
  tags.push(tag.tag_text)
end
json.tags tags
json.owner notebook.owner_id_str
if notebook.creator.nil?
  json.creator "Unknown"
else
  json.creator notebook.creator.user_name
end
if notebook.updater.nil?
  json.updater "Unknown"
else
  json.updater notebook.updater.user_name
end
json.url request.base_url + notebook_path(notebook)
