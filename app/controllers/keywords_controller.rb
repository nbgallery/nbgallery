# Controller for notebook keywords
class KeywordsController < ApplicationController
  # GET /keywords
  def index
    @keywords = Keyword
      .group(:keyword)
      .count
      .sort_by {|_keyword, count| -count + rand}
      .take(250)

    respond_to do |format|
      format.html do
        unless @keywords.empty?
          min_count = @keywords.last[1]
          max_count = @keywords.first[1]
          min_em = 0.8
          max_em = 2.4
          scale = (max_em - min_em) / (max_count - min_count)

          @keywords = @keywords
            .map {|keyword, count| [keyword, format('%4.2f', (count - min_count) * scale + min_em)]}
            .sort_by {|keyword, _size| keyword}
        end
      end
      format.json
    end
  end

  # GET /keywords/wordcloud.png
  def wordcloud
    file = File.join(GalleryConfig.directories.wordclouds, 'keywords.png')
    raise NotFound, 'Wordcloud not generated yet.' unless File.exist?(file)
    send_file(file, disposition: 'inline')
  end
end
