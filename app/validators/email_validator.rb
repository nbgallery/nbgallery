# Validates that an email address is well-formed
class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || 'is not a valid email address') unless
      GalleryLib.valid_email?(value)
  end
end
