# Sample extension for notebook review logic
module ReviewableBy
  # Class methods to override default logic in Review class
  module ClassMethods
    def compliance_review_allowed?(_review, user)
      # This overrides the default business logic for compliance/policy review
      user.org == 'Corporate Compliance Office'
    end
  end
end
