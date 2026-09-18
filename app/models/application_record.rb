class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  if GalleryConfig.mysql.multi_db_enabled
    connects_to database: { writing: :primary, reading: :primary_replica }
  end
end