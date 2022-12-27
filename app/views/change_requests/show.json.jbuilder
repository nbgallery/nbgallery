json.notebook [@change_request.notebook.id, @change_request.notebook.title, notebook_url(@change_request.notebook)]
json.extract! @change_request, :id, :requestor_comment, :owner_comment, :status
if @change_request.requestor.nil?
    json.requestor "Unknown"
else
    json.requestor @change_request.requestor.user_name
end
if @change_request.reviewer.nil?
    json.reviewer nil
else
    json.reviewer @change_request.reviewer.user_name
end

