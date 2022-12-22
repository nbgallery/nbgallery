json.groups(@groups) do |group, count|
    json.extract! group, :gid, :name, :description
    json.notebooks count
    json.url url_for(group)
end
json.tags(@tags) do |tag, count|
    json.tag tag
    json.notebooks count
    json.url "#{tag_url(tag)}"
  end
json.notebooks(@notebooks, partial: 'application/notebook_json', as: :notebook)