class NotebookFile < ApplicationRecord
  validates :uuid, uuid: true
end
