json.array!(@users) do |user|
  json.extract! user, :user_name, :first_name, :last_name, :org
  json.url user_url(user, format: :json)
end
