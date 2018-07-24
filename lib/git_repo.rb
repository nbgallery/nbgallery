# Functions for interacting with local git repo holding notebooks
module GitRepo
  class << self
    def init
      # Create and configure the git repo
      git = Git.init(GalleryConfig.directories.cache)
      git.config('user.name', 'nbgallery')
      git.config('user.email', 'nbgallery@nb.gallery')
      return if Notebook.count.zero?

      # Add all existing notebooks into git
      git.add(all: true)
      git.commit('initial commit')
      git.object('HEAD').sha
    end

    def add_and_commit(notebook, message)
      # Make this transactional out of race-condition paranoia -- we're doing
      # 3 git commands (add, commit, HEAD sha) and need them to happen as one.
      # (If 2 uploads happen at once then you could get 2 adds on 1 commit.)
      # Use flock because depending on the app server (e.g. Passenger) there
      # may be multiple processes running.
      git = Git.open(GalleryConfig.directories.cache)
      sha = nil
      lock = File.join(GalleryConfig.directories.data, '.nbgallery_git_lock')
      File.open(lock, File::RDWR | File::CREAT, 0o644) do |f|
        begin
          f.flock(File::LOCK_EX)
          git.add(File.basename(notebook.filename))
          git.commit(message)
          sha = git.object('HEAD').sha
        ensure
          f.flock(File::LOCK_UN)
        end
      end
      sha
    end
  end
end
