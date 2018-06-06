json.array!(@groups) do |group, count|
  json.extract! group, :gid, :name, :description
  json.notebooks count
  json.url url_for(group)
end
