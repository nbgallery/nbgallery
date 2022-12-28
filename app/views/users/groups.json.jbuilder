json.user do 
    json.extract! @viewed_user, :id, :user_name
    json.url user_url(@viewed_user, format: :json)
end
json.groups(@groups) do | group, count |
    json.extract! group, :name, :description, :gid, :id
    json.url group_url(group, format: :json)
    json.notebooks group.notebooks.count
end
