# Model for suggested notebooks
class SuggestedNotebook < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook
  belongs_to :source, polymorphic: true

  include ExtendableModel

  # Used to decide if a user is sufficiently "aware" of a notebook
  # to defeat it in some of the suggestion algorithms
  FeatureVectorThreshold = Math.log(5) - 0.01

  class << self
    # Concatenation of reasons
    def reasons_sql
      "GROUP_CONCAT(reason SEPARATOR '; ') AS reasons"
    end

    # Suggestion score for a notebook.
    # Currently count of reasons, excluding randomly suggested.
    def score_sql
      # TODO: SUM(score) would be ideal, but the scores from different
      # algorithms need to be normalized or at least made meaningful
      # relative to each other.
      'SUM(SIGN(score)) AS score'
    end

    def compute_all
      User.find_each do |user|
        compute_for(user)
      end
    end

    def compute_for(user)
      # Filter out things the user is already aware of
      recent_views = user.clicks
        .where('updated_at > ?', 7.days.ago)
        .group(:notebook_id)
        .pluck(:notebook_id)
      owned = user.notebooks.pluck(:id)
      created = Notebook.where(creator_id: user.id).pluck(:id)
      updated = Notebook.where(updater_id: user.id).pluck(:id)
      stars = user.stars.pluck(:notebook_id)
      defeat = Set.new(recent_views + owned + created + updated + stars)

      # Get suggestions from helper methods
      suggestors = methods.select {|m| m.to_s.start_with?('suggest_notebooks_')}
      suggested = suggestors
        .map {|suggestor| send(suggestor, user)}
        .reduce(&:+)
        .reject {|suggestion| defeat.include?(suggestion.notebook_id)}

      # Add some random suggestions
      # Note: score for these is 0 so they don't factor into total score.
      defeat.merge(suggested.map(&:notebook_id))
      random = (Notebook.readable_by(user).pluck(:id) - defeat.to_a)
        .sort_by {rand}
        .take(3)
      random.each do |id|
        suggested << SuggestedNotebook.new(
          user_id: user.id,
          notebook_id: id,
          reason: "randomly selected because we're feeling lucky!",
          score: 0.0
        )
      end

      # Import into database
      SuggestedNotebook.transaction do
        SuggestedNotebook.where(user_id: user).delete_all # no callbacks
        SuggestedNotebook.import(suggested)
      end
    end

    def suggest_notebooks_by_similar_users(user)
      max_similar_users = [User.count / 5 + 1, 50].min
      min_similarity_score = 0.4
      max_per_user = 10
      max_total = 25

      # Get a list of the most similar users
      similar_users = user.user_similarities.includes(:other_user)
        .where('score >= ?', min_similarity_score)
        .order(score: :desc)
        .limit(max_similar_users)

      # Compare feature vectors to find notebooks with high value in
      # the other vector but low value in this user's vector.
      this_vector = user.feature_vector
      suggested = Hash.new(0.0)
      similar_users.each do |sim|
        other_vector = sim.other_user.feature_vector
        # Discard this user's high-view notebooks
        other_vector.reject! {|id, _val| this_vector.fetch(id, 0) > FeatureVectorThreshold}
        # Discard other user's low-view notebooks
        other_vector.reject! {|_id, value| value < FeatureVectorThreshold}
        # Sort by difference and keep the top N
        top_n = other_vector
          .map {|id, value| [id, value - this_vector.fetch(id, 0)]}
          .sort_by {|_id, value| -value}
          .take(max_per_user)
        top_n.each {|id, value| suggested[id] += value}
      end

      # Return suggestion objects.
      # Score is not meaningful relative to other algorithms.
      suggested.sort_by {|_id, value| -value}.take(max_total).map do |id, value|
        SuggestedNotebook.new(
          user_id: user.id,
          notebook_id: id,
          reason: 'popular with similar users',
          score: value
        )
      end
    end

    def suggest_notebooks_by_similar_notebooks(user)
      vector = user.feature_vector
      max_user_notebooks = [vector.size / 5 + 1, 25].min
      #min_similarity_score = 0.4
      max_per_notebook = 10
      max_total = 25

      # Get a list of the user's most valued notebooks
      user_notebooks = vector
        .sort_by {|_id, value| -value}
        .take(max_user_notebooks)

      # For those notebooks, get the most similar other notebooks
      suggested = Hash.new(0.0)
      user_notebooks.each do |id, _value|
        notebook = Notebook.find(id)
        next unless notebook
        notebook.more_like_this(user, count: max_per_notebook).each do |nb|
          suggested[nb.id] += 1.0
        end
      end

      # Return suggestion objects.
      # Score is not meaningful relative to other algorithms.
      suggested.sort_by {|_id, value| -value}.take(max_total).map do |id, value|
        SuggestedNotebook.new(
          user_id: user.id,
          notebook_id: id,
          reason: 'similar to notebooks you like',
          score: value
        )
      end
    end

    def suggest_notebooks_for_new_users(user)
      # Return if user has viewed a few notebooks
      return [] unless user.newish_user

      # Suggest notebooks tagged with 'examples' etc
      Notebook.readable_by(user)
        .joins('LEFT OUTER JOIN tags ON tags.notebook_id = notebooks.id')
        .where("tags.tag IN ('trusted', 'buildingblocks', 'examples')")
        .sort_by {rand}
        .take(10)
        .map do |nb|
          SuggestedNotebook.new(
            user_id: user.id,
            notebook_id: nb.id,
            reason: 'recommended for new users',
            score: 1.0
          )
        end
    end

    def suggest_notebooks_from_group_membership(user)
      Notebook.where(owner: user.groups)
        .select {|nb| user.feature_vector.fetch(nb.id, 0) < FeatureVectorThreshold}
        .map do |nb|
          SuggestedNotebook.new(
            user_id: user.id,
            notebook_id: nb.id,
            reason: 'owned by one of your groups',
            score: 1.0,
            source: nb.owner
          )
        end
    end
  end
end
