json.array!(@groups) do |group, count|
  json.extract! group, :gid, :name, :description
  json.notebooks count
  json.url request.base_url + group.friendly_url
end
