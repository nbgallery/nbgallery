json.groups(@groups) do |group, count|
    json.extract! group, :gid, :name, :description
    json.notebooks count
    json.url url_for(group)
end
json.tags(@tag_text_with_counts) do |tag_text, count|
    json.tag tag_text
    json.notebooks count
    json.url "#{tag_url(tag_text)}"
  end
json.notebooks(@notebooks, partial: 'application/notebook_json', as: :notebook)