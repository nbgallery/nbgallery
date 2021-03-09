class NotebookFile < ActiveRecord::Base
  validates :uuid, uuid: true
end
