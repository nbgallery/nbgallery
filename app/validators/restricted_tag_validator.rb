# Check for restricted tags
# TODO: #360 - Fix when tag is normalized
class RestrictedTagValidator < ActiveModel::Validator
  def validate(record)
    restricted = GalleryConfig.restricted_tags.include?(record.tag_text)
    admin = record.user&.admin?
    record.errors.add :tag, (options[:message] || "#{record.tag_text} tag is restricted to admins") if
      restricted && !admin
  end
end
