# RecommendedReviewer model
class RecommendedReviewer < ApplicationRecord
  belongs_to :user
  belongs_to :review

  # Recommenders to match reviews with potential reviewers
  class << self
    # Helper to count package usage in the corpus of notebooks
    def count_packages
      # language => package => count
      all = Hash.new {|hash, lang| hash[lang] = Hash.new(0)}
      # creator => package => count (capped to prevent prolific authors from always being on top)
      by_creator = Hash.new {|hash, creator| hash[creator] = Hash.new(0)}
      # notebook => set of packages
      by_notebook = {}

      # Go through the notebooks and count packages
      Notebook.find_each(batch_size: 100) do |nb|
        packages = Set.new(nb.notebook.packages.map {|p| "#{nb.lang}:#{p}"})
        by_notebook[nb.id] = packages
        packages.each do |p|
          by_creator[nb.creator_id][p] = [by_creator[nb.creator_id][p] + 1, 5].min
          all[nb.lang][p] += 1
        end
      end

      # Scale by most common package (per language)
      all.each do |_lang, lang_packages|
        max = lang_packages.map(&:second).max
        lang_packages.each {|pkg, count| lang_packages[pkg] = [1.0 - count.to_f / max, 0.0001].max}
      end

      [all, by_creator, by_notebook]
    end

    # Helper to score how well a potential reviewer's use of language packages
    # matches the packages used in the notebook to be reviewed.
    def package_score(lang_packages, notebook_packages, reviewer_packages)
      reviewer_match = 0.0
      weight_sum = 0.0
      notebook_packages.each do |pkg|
        weight = lang_packages[pkg]
        reviewer_match += reviewer_packages.fetch(pkg, 0.0) * weight
        weight_sum += weight
      end
      weight_sum.nonzero? ? reviewer_match / weight_sum : 0.0
    end

    # Helper to get top more-like-this notebooks
    def more_like_this(notebook, topn)
      Sunspot
        .more_like_this(notebook) {paginate page: 1, per_page: topn}
        .results
        .group_by(&:creator_id)
        .map {|user_id, notebooks| [user_id, notebooks.count]}
        .to_h
    end

    # Identify potential reviewers for each technical review in the queue
    def recommend_technical_reviewers
      # Language package usage across all notebooks
      all_packages, by_creator, by_notebook = count_packages

      # Limit reviews to top X% of authors
      top_authors = UserSummary.where('author_rep_pct >= 40.0').map(&:user_id)

      # Process each review
      Review.includes(:notebook).where(revtype: 'technical', status: 'queued').find_each do |review|
        # Relevant package usage
        lang_packages = all_packages[review.notebook.lang]
        notebook_packages = by_notebook[review.notebook_id]

        # Top N similar notebooks, grouped by creator
        mlt = more_like_this(review.notebook, 25)

        # Score each potential reviewer
        reviewers = top_authors.reject {|user_id| user_id == review.notebook.creator_id}
        scores = reviewers.map do |user_id|
          reviewer_packages = by_creator[user_id]
          pkg_score = package_score(lang_packages, notebook_packages, reviewer_packages)
          mlt_score = [mlt.fetch(user_id, 0.0), 10.0].min
          [user_id, mlt_score + pkg_score]
        end
        top_users = scores.sort_by {|_user_id, score| -score}.take(10)

        # Add top candidates to database
        records = top_users.map do |user_id, score|
          RecommendedReviewer.new(
            review: review,
            user_id: user_id,
            score: score
          )
        end
        RecommendedReviewer.transaction do
          RecommendedReviewer.where(review: review).delete_all # no callbacks
          RecommendedReviewer.import(records)
        end
      end
      nil
    end

    # Helper to get top users of a notebook
    def top_notebook_users(notebook, topn)
      notebook
        .clicks
        .includes(user: [:user_summary])
        .where(action: ['ran notebook', 'executed notebook', 'downloaded notebook'])
        .where('updated_at > ?', 180.days.ago)
        .where.not(user_id: notebook.creator_id)
        .select('user_id, count(*) AS c')
        .group(:user_id)
        .order('c DESC')
        .limit(topn * 2)
        .map {|click| [click.user, click.c]}
    end

    # Identify potential reviewers for each functional review in the queue
    def recommend_functional_reviewers
      Review.includes(:notebook).where(revtype: 'functional', status: 'queued').find_each do |review|
        # Figure out who used the notebook the most
        topn = 10
        top_users = top_notebook_users(review.notebook, topn)
        next if top_users.empty?

        # Scale by the max then average in the user reputation score
        max = top_users.first.second.to_f
        top_users = top_users
          .map {|user, score| [user, (score / max + user.user_rep_pct / 100.0) / 2.0]}
          .sort_by {|_user, score| -score}
          .take(topn)

        # Add top candidates to database
        records = top_users.map do |user, score|
          RecommendedReviewer.new(
            review: review,
            user: user,
            score: score
          )
        end
        RecommendedReviewer.transaction do
          RecommendedReviewer.where(review: review).delete_all # no callbacks
          RecommendedReviewer.import(records)
        end
      end
      nil
    end

    # Identify potential reviewers for each compliance review in the queue
    def recommend_compliance_reviewers
      Review.includes(:notebook).where(revtype: 'compliance', status: 'queued').find_each do |_review|
      end
      nil
    end
  end
end
