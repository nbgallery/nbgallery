json.array!(@keywords) do |keyword, _count|
  json.keyword keyword
  json.url request.base_url + "/notebooks?q=#{CGI.escape(keyword)}"
end
