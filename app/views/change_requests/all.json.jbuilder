json.array!(@change_requests) do | change_request |
    json.notebook [id: change_request.notebook.id, title: change_request.notebook.title, url: notebook_url(change_request.notebook)]
    if change_request.requestor.nil?
        json.requestor "Unknown"
    else
        json.requestor change_request.requestor.user_name
    end
    if change_request.reviewer.nil?
        json.reviewer nil
    else
        json.reviewer change_request.reviewer.user_name
    end
    json.requestor_comment change_request.requestor_comment
    json.owner_comment change_request.owner_comment
    json.created_at change_request.created_at
    json.updated_at change_request.updated_at
    json.status change_request.status
end
