# Model for group suggestions ("you might like notebooks owned by this group")
class SuggestedGroup < ApplicationRecord
  belongs_to :user
  belongs_to :group

  include ExtendableModel

  class << self
    def compute_all
      User.find_each(batch_size: 100) do |user|
        compute_for(user)
      end
    end

    def compute_for(user)
      # Get suggestions from helper methods
      suggestors = methods.select {|m| m.to_s.start_with?('suggest_groups_')}
      suggested = suggestors
        .map {|suggestor| send(suggestor, user)}
        .reduce(&:+)
        .map {|id| SuggestedGroup.new(user_id: user.id, group_id: id)}

      # Import into database
      SuggestedGroup.transaction do
        SuggestedGroup.where(user_id: user).delete_all # no callbacks
        SuggestedGroup.import(suggested)
      end
    end

    # Suggest groups that own notebooks suggested for the user
    def suggest_groups_from_suggested_notebooks(user)
      Set.new(
        SuggestedNotebook
          .select("notebooks.owner_id")
          .joins(:notebook)
          .where("user_id = ? AND owner_type = 'Group'", user.id)
          .map(&:owner_id)
      )
    end

    # Suggest any of the user's groups that own notebooks
    def suggest_groups_from_membership(user)
      Set.new(Notebook.where(owner: user.groups).map(&:owner_id))
    end
  end
end
