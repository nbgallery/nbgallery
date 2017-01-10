# Change request helpers
module ChangeRequestsHelper
  def change_request_class(status)
    case status
    when 'pending'
      'danger'
    when 'accepted'
      'success'
    else
      ''
    end
  end
end
