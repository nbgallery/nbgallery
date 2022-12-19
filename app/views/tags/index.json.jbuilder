json.array!(@tags) do |tag, count|
  json.tag tag
  json.notebooks count
  json.url "#{tag_url(tag)}"
end
