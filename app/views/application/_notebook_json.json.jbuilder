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
json.owner notebook.owner_id_str
json.creator notebook.creator.email
json.updater notebook.updater.email
json.url request.base_url + notebook.friendly_url
