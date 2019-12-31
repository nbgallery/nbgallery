# Model for user execution environments (Jupyter notebook servers)
class Environment < ActiveRecord::Base
  belongs_to :user
  validates(
    :name,
    presence: true,
    uniqueness: { scope: :user },
    format: {
      with: /\A[A-Za-z0-9-]+\z/,
      message: 'Environment name can only use uppercase, lowercase, digits and hyphens'
    }
  )
  validates :url, presence: true, uniqueness: { scope: :user }
end
