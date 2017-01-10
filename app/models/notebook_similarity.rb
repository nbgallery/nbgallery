require 'delegate'
require 'matrix'
require 'tf-idf-similarity'

# Model for notebook similarity scores
class NotebookSimilarity < ActiveRecord::Base
  belongs_to :notebook
  belongs_to :other_notebook, class_name: 'Notebook'

  validates :notebook, :other_notebook, :score, presence: true

  # Nightly computation methods
  class << self
    # Generate TF-IDF corpus from notebook text
    def generate_corpus
      ids = []
      corpus = []
      tags = Tag
        .select("notebook_id, GROUP_CONCAT(tag SEPARATOR ' ') AS tags")
        .group(:notebook_id)
        .map {|row| [row.notebook_id, row.tags]}
        .to_h
      Notebook.find_each do |nb|
        begin
          content = nb.notebook.text rescue ''
          text = "#{Notebook.groom(nb.title)} #{Notebook.groom(nb.description)} #{tags[nb.id]} #{content}"
          corpus << TfIdfSimilarity::Document.new(text)
          ids << nb.id
        rescue => ex
          Rails.logger.info("NotebookSimilarity: #{ex.class} #{ex.message}")
        end
      end
      [ids, corpus]
    end

    # Compute and database similarity scores using TF-IDF.
    # This is quadratic in number of notebooks.
    def compute_similarity(ids, corpus)
      start = Time.current
      model = TfIdfSimilarity::TfIdfModel.new(corpus, library: :narray)
      matrix = model.similarity_matrix
      Rails.logger.info("tf-idf model build time: #{Time.current - start}")
      (0...ids.size).each do |i|
        to_insert = []
        (0...ids.size).each do |j|
          next if i == j
          to_insert << NotebookSimilarity.new(
            notebook_id: ids[i],
            other_notebook_id: ids[j],
            score: matrix[model.document_index(corpus[i]), model.document_index(corpus[j])]
          )
        end
        NotebookSimilarity.import(
          to_insert,
          on_duplicate_key_update: [:score],
          validate: false,
          batch_size: 1000
        )
      end
      model
    end

    # Pick out top keywords for each notebook
    def compute_keywords(ids, corpus, model)
      keywords = []
      blacklist = GalleryLib.keyword_blacklist
      whitelist = GalleryLib.keyword_whitelist
      (0...ids.size).each do |i|
        doc = corpus[i]
        term_counts = doc.term_counts.select do |term, _count|
          (term.size > 3 || whitelist.include?(term)) && !blacklist.include?(term)
        end
        tfidfs = term_counts.map do |term, _count|
          [term, model.tf(doc, term) * model.idf(term)]
        end
        tfidfs.sort_by! {|_term, tfidf| -tfidf}
        tfidfs.take(20).each do |term, tfidf|
          keywords << Keyword.new(
            notebook_id: ids[i],
            keyword: term,
            tfidf: tfidf,
            tf: model.tf(doc, term),
            idf: model.idf(term)
          )
        end
      end
      Keyword.transaction do
        Keyword.delete_all # no callbacks
        Keyword.import(keywords, validate: false, batch_size: 50)
      end
    end

    # Compute notebook similarities and top keywords
    def compute_all
      ids, corpus = generate_corpus
      model = compute_similarity(ids, corpus)
      compute_keywords(ids, corpus, model)
    end
  end
end
