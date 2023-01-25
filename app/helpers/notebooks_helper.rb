# Helper for rendering notebooks
module NotebooksHelper
  def markdown(text)
    @renderer ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
    @renderer.render(text)
  end

  def code(lang, text)
    begin
      user_pref = UserPreference.find_by(user_id: @user.id)
    rescue => e
      user_pref = nil
    end
    lang = 'text' if lang.blank?
    formatter = Rouge::Formatters::HTML.new
    formatter = Rouge::Formatters::HTMLLinewise.new(formatter, class: "code-block") unless user_pref && user_pref.disable_row_numbers
    begin
      output = Rouge.highlight text, lang, formatter
    rescue StandardError
      output = Rouge.highlight text, 'text', formatter
    end
    "<pre class=\"Highlight\">" + output + "</pre>"
  end

  def raw(text)
    code 'text', text
  end

  def render_description(description,truncate = false)
    if (truncate)
      return strip_tags(description).truncate(500,omission: "...")
    else
      if GalleryConfig.markdown != nil && GalleryConfig.markdown.description_enabled
        markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true)
        if (GalleryConfig.notebooks.allow_html_description)
          return markdown.render(description)
        else
          return markdown.render(strip_tags(description))
        end
      elsif (GalleryConfig.notebooks.allow_html_description)
        return description
      else
        return strip_tags(description)
      end
    end
  end

  def review_status(nb)
    recent = 0
    total = 0
    GalleryConfig.reviews.to_a.each do |revtype, options|
      next unless options.enabled
      total += 1
      recent += 1 if nb.recent_review?(revtype)
    end
    if recent.zero?
      :none
    elsif recent == total
      :full
    else
      :partial
    end
  end

  def review_status_string(nb)
    reviewed = GalleryConfig
      .reviews
      .to_a
      .select {|revtype, options| options.enabled && nb.recent_review?(revtype)}
      .map {|_revtype, options| options.label}
    if reviewed.present?
      "This notebook has been reviewed for #{reviewed.to_sentence} quality."
    else
      'This notebook has no recent reviews.'
    end
  end

  # Return the latest prior revision with a full review
  def fully_reviewed_prior_revision(nb, user)
    review_types = GalleryConfig.reviews.to_a
      .select {|revtype, options| options.enabled }
      .map {|revtype, options| revtype.to_s}

    revisions = nb.revision_list(user)
    # first item will be current revision so remove
    revisions.shift

    reviews = Review.where(status: 'completed',
                          notebook_id: nb[:id],
                          revision_id: revisions.map{|r| r[:id]},
                          revtype: review_types)
                        .order(revision_id: :desc)
                        .group_by{|r| r[:revision_id]}
    reviews.each do |revision_id, revision_reviews|
      rev_review_types = revision_reviews.map {|rev| rev[:revtype]}
      return revision_reviews[0].revision if (review_types - rev_review_types).empty?
    end
    nil
  end

  def prior_revision_review_status_string(revision)
    reviewed = GalleryConfig
      .reviews
      .to_a
      .select {|revtype, options| options.enabled}
      .map {|_revtype, options| options.label}
    "A previous revision (#{revision[:commit_id].first(8)}) of this notebook has been fully reviewed for #{reviewed.to_sentence} quality."
  end
end
