# Check for restricted tags
class RestrictedTagValidator < ActiveModel::Validator
  def validate(record)
    restricted = GalleryConfig.restricted_tags.include?(record[:tag])
    admin = record.user&.admin?
    record.errors[:tag] = (options[:message] || "#{record[:tag]} tag is restricted to admins") if
      restricted && !admin
  end
end
