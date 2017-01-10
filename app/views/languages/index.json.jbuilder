json.array!(@languages) do |lang, count|
  json.language lang
  json.notebooks count
  json.url request.base_url + "/languages/#{lang}"
end
