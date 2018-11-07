# Model for suggested notebooks
class SuggestedNotebook < ActiveRecord::Base
  belongs_to :user
  belongs_to :notebook
  belongs_to :source, polymorphic: true

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
      User.find_each(batch_size: 100) do |user|
        compute_for(user)
      end
    end

    # Don't recommend things the user is already aware of
    def user_defeats(user)
      # TODO: (?) add explicit "never show this again" option?
      recent_views = user.clicks
        .where('updated_at > ?', 7.days.ago)
        .group(:notebook_id)
        .pluck(:notebook_id)
      owned = user.notebooks.pluck(:id)
      created = user.notebooks_created.pluck(:id)
      updated = user.notebooks_updated.pluck(:id)
      stars = user.stars.pluck(:notebook_id)
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
      random = (Notebook.readable_by(user).pluck(:id) - defeat.to_a)
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
      similar_users = user.user_similarities.pluck(:other_user_id)
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

      # For each favorite nb, how similar others need to be
      #min_similarity_score = 0.4

      # For each favorite nb, how many others to consider
      max_per_notebook = 10

      # How many notebooks to return
      num_to_return = 25

      # Cap the max score before scaling to the desired range.
      score_cap = 4.0

      # Range for scaling the final scores
      desired_min = 0.5
      desired_max = 1.0

      # Get a list of the user's most valued notebooks
      user_notebooks = vector
        .sort_by {|_id, value| -value}
        .take(max_user_notebooks)
        .to_h

      # For those notebooks, get the most similar other notebooks
      suggested = Hash.new(0.0)
      user_notebooks.each_key do |id|
        notebook = Notebook.find(id)
        next unless notebook
        notebook.more_like_this(user, count: max_per_notebook).each_with_index do |nb, i|
          # Solr's MLT doesn't have a score, so go from 1.0 down to 0.5
          suggested[nb.id] += 1.0 - i * (0.5 / max_per_notebook)
        end
      end

      # Discard anything that was in the initial list of user's notebooks
      user_notebooks.each_key {|id| suggested.delete(id)}
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
            score: 0.70,
            source: nb.owner
          )
        end
    end
  end
end
