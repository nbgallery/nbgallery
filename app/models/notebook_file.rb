class NotebookFile < ActiveRecord::Base
  belongs_to :notebook, class_name: 'Notebook', inverse_of: 'notebooks_created'

  validates :uuid, uniqueness: { case_sensitive: false }
  validates :uuid, uuid: true
end
