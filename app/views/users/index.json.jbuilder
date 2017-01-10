json.array!(@users) do |user|
  json.extract! user, :id, :email, :first_name, :last_name, :org, :admin
  json.url user_url(user, format: :json)
end
