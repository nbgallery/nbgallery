# Model for suggested tags ("you might like notebooks tagged with...")
class SuggestedTag < ApplicationRecord
  belongs_to :user

  include ExtendableModel

  class << self
    def compute_all
      User.find_each(batch_size: 100) do |user|
        compute_for(user)
      end
    end

    def compute_for(user)
      # Get suggestions from helper methods
      suggestors = methods.select {|m| m.to_s.start_with?('suggest_tags_')}
      suggested = suggestors
        .map {|suggestor| send(suggestor, user)}
        .reduce(&:+)
        .map {|tag| SuggestedTag.new(user_id: user.id, tag: tag)}

      # Import into database
      SuggestedTag.transaction do
        SuggestedTag.where(user_id: user).delete_all # no callbacks
        SuggestedTag.import(suggested)
      end
    end

    # Suggest tags that are on notebooks suggested for the user
    # TODO: #360 - Fix when tag is normalized
    def suggest_tags_from_suggested_notebooks(user)
      Set.new(
        SuggestedNotebook
          .joins('JOIN tags on tags.notebook_id = suggested_notebooks.notebook_id')
          .where(user_id: user.id)
          .select('tag as tag_text, count(*) AS count')
          .group(:tag)
          .map {|e| [e.tag_text, e.count]}
          .sort_by {|_tag_text, count| -count}
          .take(25)
          .map(&:first)
      )
    end
  end
end
