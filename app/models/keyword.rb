# Model for top notebook keywords
class Keyword < ActiveRecord::Base
  belongs_to :notebook

  include ExtendableModel

  #########################################################
  # Compute top keywords
  #########################################################

  def self.notebook_text(notebook)
    content = notebook.notebook.text rescue ''
    "#{Notebook.groom(notebook.title)} #{Notebook.groom(notebook.description)} #{content}"
  end

  def self.compute_all
    tfidf = TfIdf.new
    tfidf.stopwords = GalleryLib.keyword_blacklist.to_a

    # Change the tokenization scheme
    tfidf.class_eval do
      def get_tokens(input)
        input.scan(/[A-Za-z]\w+/).map(&:downcase)
      end
    end

    # Build the corpus
    Notebook.find_each do |nb|
      tfidf.add_input_document(notebook_text(nb))
    end

    # Go back through to get hte top keywords from each notebook
    Notebook.find_each do |nb|
      keywords = tfidf
        .doc_keywords(notebook_text(nb))
        .take(20)
        .select {|_term, score| score > 0.0}

      keywords.map! do |term, score|
        idf = tfidf.idf(term)
        Keyword.new(
          notebook_id: nb.id,
          keyword: term,
          tfidf: score,
          tf: score / idf,
          idf: idf
        )
      end

      Keyword.transaction do
        Keyword.where(notebook_id: nb.id).delete_all # no callbacks
        Keyword.import(keywords, validate: false)
      end
    end
  end

  #########################################################
  # Wordcloud methods
  #########################################################

  def self.wordcloud_image_file
    File.join(GalleryConfig.directories.wordclouds, 'keywords.png')
  end

  def self.wordcloud_map_file
    File.join(GalleryConfig.directories.wordclouds, 'keywords.map')
  end

  def self.wordcloud_exists?
    File.exist?(wordcloud_image_file) && File.exist?(wordcloud_map_file)
  end

  def self.wordcloud_map
    File.read(wordcloud_map_file) if File.exist?(wordcloud_map_file)
  end

  def self.generate_wordcloud
    counts = Keyword.group(:keyword).count
      .select {|keyword, _count| filter_for_wordcloud(keyword)}
      .sort_by {|_keyword, count| -count + rand}
    make_wordcloud(
      counts,
      'keywords',
      '/keywords/wordcloud.png',
      '/notebooks?q=%s&sort=score',
      width: 800,
      height: 600
    )
  end

  def self.filter_for_wordcloud(_tag)
    true
  end
end
