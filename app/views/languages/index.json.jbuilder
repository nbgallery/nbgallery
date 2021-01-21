json.array!(@languages) do |lang, count|
  json.language lang
  json.notebooks count
  json.url request.base_url + "#{language_path(lang)}"
end
