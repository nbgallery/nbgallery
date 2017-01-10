# Validates that a uuid has the right format
class UuidValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    message = options[:message] || 'is not a well-formatted UUID'
    record.errors[attribute] << message unless GalleryLib.uuid?(value)
  end
end
