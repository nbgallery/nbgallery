# Model for suggested notebooks
class SuggestedNotebook < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
  belongs_to :source, polymorphic: true, optional:true

  include ExtendableModel

  class << self
    # Concatenation of reasons
    def reasons_sql
      "GROUP_CONCAT(reason SEPARATOR '; ') AS reasons"
    end

    # Suggestion score for a notebook.
    # Sum of scores from each algorithm.
    def score_sql
      'SUM(score) AS score'
    end

    def compute_all
      day_of_week = Time.current.wday
      old_threshold = 30.days.ago
      recomputed = 0
      users_with_suggestions = SuggestedNotebook.pluck('DISTINCT(user_id)').to_set
      User.find_each(batch_size: 100) do |user|
        recompute =
          user.updated_at > old_threshold ||
          user.id % 7 == day_of_week ||
          !users_with_suggestions.include?(user.id)
        next unless recompute
        compute_for(user)
        recomputed += 1
      end
      pct = recomputed.to_f / User.count
      "recomputed #{recomputed}/#{User.count} (#{format('%.3f', pct)})"
    end

    # Don't recommend things the user is already aware of
    def user_defeats(user)
      # TODO: (?) add explicit "never show this again" option?
      recent_views = user.clicks
        .select(:notebook_id)
        .where('updated_at > ?', 30.days.ago)
        .distinct
        .map(&:notebook_id)
      owned = user.notebooks.map(&:id)
      created = user.notebooks_created.map(&:id)
      updated = user.notebooks_updated.map(&:id)
      stars = user.stars.map(&:id)
      Set.new(recent_views + owned + created + updated + stars)
    end

    def compute_for(user)
      # Get suggestions from helper methods
      defeat = user_defeats(user)
      suggestors = methods.select {|m| m.to_s.start_with?('suggest_notebooks_')}
      suggested = suggestors
        .map {|suggestor| send(suggestor, user)}
        .reduce(&:+)
        .reject {|suggestion| defeat.include?(suggestion.notebook_id)}

      # Add some random suggestions
      # Note: score for these is 0 so they don't factor into total score.
      defeat.merge(suggested.map(&:notebook_id))
      random = (Notebook.readable_by(user).map(&:id) - defeat.to_a)
        .shuffle
        .take(3)
      random.each do |id|
        suggested << SuggestedNotebook.new(
          user_id: user.id,
          notebook_id: id,
          reason: "randomly selected because we're feeling lucky!",
          score: 0.0
        )
      end

      # Make sure score is in [0,1]
      suggested.each {|s| s.score = [[s.score, 1.0].min, 0.0].max}

      # Import into database
      SuggestedNotebook.transaction do
        SuggestedNotebook.where(user_id: user).delete_all # no callbacks
        SuggestedNotebook.import(suggested)
      end
    end

    def scale_similarity_suggestions(suggested, score_cap, desired_min, desired_max)
      return suggested if suggested.empty?

      # Sort and cap the scores before we scale
      suggested = suggested.sort_by {|_id, value| -value}
      suggested.map! {|id, value| [id, [value, score_cap].min]}

      # Scale the score to the desired range
      max_score = suggested.first.last
      min_score = suggested.last.last
      if max_score - min_score < 0.0000001
        # All scores are the same; set to max
        suggested.map! {|id, _value| [id, desired_max]}
      else
        divisor = (max_score - min_score) / (desired_max - desired_min)
        suggested.map! {|id, value| [id, (value - min_score) / divisor + desired_min]}
      end

      #x = (0...suggested.count).to_a
      #y = suggested.map(&:last)
      #p x
      #p y

      suggested
    end

    def suggest_notebooks_by_similar_users(user)
      # Range for scaling the final scores
      score_cap = 10.0
      desired_min = 0.5
      desired_max = 1.0

      # How many notebooks to return
      num_to_return = 25

      # Recent activity by similar users
      similar_users = user.user_similarities.map(&:other_user_id)
      suggested = Click
        .where('updated_at > ?', 90.days.ago)
        .where(user_id: similar_users)
        .select("notebook_id, SUM(IF(action='executed notebook',1.0,0.5)) AS score")
        .group('notebook_id')
        .order('score DESC')
        .take(num_to_return)
        .map {|e| [e.notebook_id, Math.log(1.0 + e.score)]}
        .to_h
      return [] if suggested.empty?

      # Finalize scores
      suggested = scale_similarity_suggestions(suggested, score_cap, desired_min, desired_max)

      # Return the top suggestion objects.
      suggested.take(num_to_return).map do |id, value|
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

      # How many of user's favorite notebooks to consider
      max_user_notebooks = [vector.size / 5 + 1, 25].min

      # How many notebooks to return
      num_to_return = 25

      # Range for scaling the final scores
      score_cap = 5.0
      desired_min = 0.5
      desired_max = 1.0

      # Get a list of the user's most valued notebooks
      user_notebooks = vector
        .sort_by {|_id, value| -value}
        .take(max_user_notebooks)
        .map(&:first)

      # For those notebooks, get the most similar other notebooks
      suggested = NotebookSimilarity
        .where(notebook_id: user_notebooks)
        .select('other_notebook_id, SUM(score) AS sum_score')
        .group(:other_notebook_id)
        .order('sum_score DESC')
        .take(num_to_return)
        .map {|e| [e.other_notebook_id, e.sum_score]}
        .to_h

      # Discard anything that was in the initial list of user's notebooks
      user_notebooks.each {|id| suggested.delete(id)}
      return [] if suggested.empty?

      # Finalize scores
      suggested = scale_similarity_suggestions(suggested, score_cap, desired_min, desired_max)

      # Return the top suggestion objects.
      suggested.take(num_to_return).map do |id, value|
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
        .group('notebooks.id')
        .shuffle
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
        .reject {|nb| user.feature_vector.include?(nb.id)}
        .map do |nb|
          SuggestedNotebook.new(
            user_id: user.id,
            notebook_id: nb.id,
            reason: 'owned by one of your groups',
            score: 0.25,
            source: nb.owner
          )
        end
    end
  end
end
