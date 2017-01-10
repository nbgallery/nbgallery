# Validates that something is not-nil but blank/false is ok
# (This is different from the presence validator.)
class NotNilValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    message = options[:message] || 'must be set'
    record.errors[attribute] << message if value.nil?
  end
end
