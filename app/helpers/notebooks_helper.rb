require 'kramdown/converter/syntax_highlighter/rouge'
require 'github/markup'

# Helper for rendering notebooks
module NotebooksHelper
  # Adds support for embedding markdown in slim
  class Renderer < Slim::Embedded::InterpolateTiltEngine
    # Add rouge syntax highlighting to redcarpet renderer
    class SyntaxHighlighting < Redcarpet::Render::HTML
      def block_code(code, language)
        language = 'text' if language.blank?
        begin
          Rouge.highlight code, language, 'html'
        rescue StandardError
          Rouge.highlight code, 'text', 'html'
        end
      end
    end

    # Convert bare URLs into links
    def autolink(html)
      pipeline = HTML::Pipeline.new([HTML::Pipeline::AutolinkFilter])
      pipeline.call(html)[:output].to_s
    end

    # Render with redcarpet
    # Known problems:
    #   * ``` code blocks without language render as inline code
    def render_markdown_redcarpet(text)
      markdown = Redcarpet::Markdown.new(
        SyntaxHighlighting,
        tables: true,
        fenced_code_blocks: true
      )
      autolink(markdown.render(text))
    end

    # Render with kramdown
    # Known problems:
    #   * Math hack - see below
    def render_markdown_kramdown(text)
      markdown = Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: :rouge, math_engine: nil)
      html = markdown.to_html

      # Undo kramdown's parsing of $$math$$ -- mathjax will handle it
      html.gsub!(%r{<span class="kdmath">(.*?)</span>}, '$\1$')

      autolink(html)
    end

    # Render with github-markup
    # Known problems:
    #   * code blocks / syntax highlighting not working (TODO)
    def render_markdown_github(text)
      autolink(GitHub::Markup.render('filename.md', text))
    end

    # Render with html-pipeline
    def render_markdown_pipeline(text)
      # Syntax pipeline uses css class "highlight-#{lang}" by default.
      # This overrides that to just use "highlight".
      context = { scope: 'highlight' }
      filters = [
        HTML::Pipeline::MarkdownFilter,
        HTML::Pipeline::SyntaxHighlightFilter,
        HTML::Pipeline::AutolinkFilter
      ]
      pipeline = HTML::Pipeline.new(filters, context)
      pipeline.call(text)[:output].to_s
    end

    # For testing/comparing
    def render_markdown_all(text)
      html = '<hr><b><i>redcarpet</i></b><br>'
      html += render_markdown_redcarpet(text) + '<br>'
      html += '<hr><b><i>kramdown</i></b><br>'
      html += render_markdown_kramdown(text) + '<br>'
      html += '<hr><b><i>github</i></b><br>'
      html += render_markdown_github(text) + '<br>'
      html += '<hr><b><i>pipeline</i></b><br>'
      html += render_markdown_pipeline(text) + '<br>'
      html + '<hr>'
    end

    def render_markdown(text, method=:pipeline)
      func = "render_markdown_#{method}".to_sym
      html = send(func, text)
      ActionController::Base.helpers.sanitize(html)
    end

    def tilt_render(_, _, text)
      output_protector.unprotect(interpolation.call(render_markdown(text)))
    end
  end

  Slim::Embedded.register :markdown, Renderer

  def markdown(text)
    @renderer ||= Renderer.new
    @renderer.render_markdown text
  end

  def code(lang, text)
    lang = 'text' if lang.blank?
    markdown "```#{lang}\n#{text}\n```"
  end

  def raw(text)
    code 'text', text
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
