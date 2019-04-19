module Devise
  module Strategies
    # Devise strategy for external authentication mechanism
    class ExternalAuth < Base
      def authenticate!
        # Insert code here to populate a User object.
        # For example you might get an email address from some external source
        # and use that to look up the User in the database:
        #   user = User.find_or_initialize_by(email: external_response[:email])
        # Then set fields as needed and save:
        #   user.save!
        # Devise expects this at the end:
        #   success!(user)
      end

      def valid?
        # Insert code to tell Devise when this strategy is usable
      end
    end
  end
end
