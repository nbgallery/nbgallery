json.array!(@tag_text_with_counts) do |tag_text, count|
  json.tag tag_text
  json.notebooks count
  json.url "#{tag_url(tag_text)}"
end
