# Model for user execution environments (Jupyter notebook servers)
class Environment < ApplicationRecord 
  belongs_to :user
  validates(
    :name,
    presence: true,
    uniqueness: { scope: :user },
    format: {
      with: /\A[A-Za-z0-9-]+\z/,
      message: 'Environment name can only contain uppercase, lowercase, digits and hyphens characters'
    }
  )
  validates :url, presence: true, uniqueness: { scope: :user }
end
