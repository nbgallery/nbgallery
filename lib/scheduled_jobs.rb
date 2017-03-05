# Functions to run on a periodic basis
module ScheduledJobs
  class << self
    def job_files
      files = Dir[Rails.root.join('config', 'cronic.d', '*.rb')]
      GalleryConfig.directories.extensions.each do |dir|
        files += Dir[File.join(dir, '*', 'cronic.d', '*.rb')]
      end
      files
    end

    def log(message)
      Rails.logger.info(message)
      # Print to stdout so it goes to cronic.log too
      # rubocop: disable Rails/Output
      puts "#{Time.current}: #{message}" if defined?(Cronic::Scheduler)
      # rubocop: enable Rails/Output
    end

    def run(name)
      log("SCHEDULER: running #{name}")
      send(name)
      log("SCHEDULER: #{name} complete")
    rescue => ex
      log("SCHEDULER: error running #{name}: #{ex.class}: #{ex.message}")
    end

    def hello
      log('Hello, world!')
    end

    def nightly_computation
      log('COMPUTE: beginning nightly computation')

      # Similarity scores
      # These are used for notebook suggestions.
      #start = Time.current
      #NotebookSimilarity.compute_all
      #log("COMPUTE: notebook similarity #{Time.current - start}")

      start = Time.current
      UsersAlsoView.compute
      log("COMPUTE: users also viewed #{Time.current - start}")

      start = Time.current
      UserSimilarity.compute_all
      log("COMPUTE: user similarity #{Time.current - start}")

      # Suggestions
      # Notebook suggestions are used for tag/group suggestions.
      start = Time.current
      SuggestedNotebook.compute_all
      log("COMPUTE: notebook suggestions #{Time.current - start}")

      start = Time.current
      SuggestedGroup.compute_all
      log("COMPUTE: group suggestions #{Time.current - start}")

      start = Time.current
      SuggestedTag.compute_all
      log("COMPUTE: tag suggestions #{Time.current - start}")

      # Wordclouds
      start = Time.current
      Tag.generate_wordcloud
      log("COMPUTE: tag cloud #{Time.current - start}")

      #start = Time.current
      #Keyword.generate_wordcloud
      #log("COMPUTE: keyword cloud #{Time.current - start}")

      #start = Time.current
      #Notebook.generate_all_wordclouds
      #log("COMPUTE: notebook clouds #{Time.current - start}")
    end

    def age_off
      Stage.age_off
      ChangeRequest.age_off
    end

    def notebook_summaries
      NotebookSummary.generate_all
    end
  end
end
