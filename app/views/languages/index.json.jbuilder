json.array!(@languages) do |lang, version, count|
  json.language "#{lang}#{version ? ' ' + version : ''}"
  json.notebooks count
  if version
    json.url "#{language_url(lang+version)}"
  else
    json.url "#{language_url(lang)}"
  end
end
