# Functions for interacting with local git repo holding notebooks
module GitRepo
  class << self
    # Initial commit - snapshot any existing notebooks
    def init
      # Create and configure the git repo
      git = Git.init(GalleryConfig.directories.repo)
      git.config('user.name', 'nbgallery')
      git.config('user.email', 'nbgallery@nb.gallery')
      return if Notebook.count.zero?

      # Add all existing notebooks into git
      git.add(all: true)
      git.commit('initial commit')
      git.object('HEAD').sha
    end

    # Commit a change to a notebook
    def add_and_commit(notebook, message, remove=false)
      # Make this transactional out of race-condition paranoia -- we're doing
      # 3 git commands (add, commit, HEAD sha) and need them to happen as one.
      # (If 2 uploads happen at once then you could get 2 adds on 1 commit.)
      # Use flock because depending on the app server (e.g. Passenger) there
      # may be multiple processes running.
      git = Git.open(GalleryConfig.directories.repo)
      sha = nil
      lock = File.join(GalleryConfig.directories.data, '.nbgallery_git_lock')
      File.open(lock, File::RDWR | File::CREAT, 0o644) do |f|
        begin
          f.flock(File::LOCK_EX)
          if remove
            File.delete(notebook.git_filename)
            git.remove(notebook.git_basename)
          else
            notebook.save_git_version
            git.add(notebook.git_basename)
          end
          git.commit(message)
          sha = git.object('HEAD').sha
        ensure
          f.flock(File::LOCK_UN)
        end
      end
      sha
    end

    # Return the notebook content at the specified commit
    def content(notebook, commit_id)
      git = Git.open(GalleryConfig.directories.repo)
      JupyterNotebook.from_git_format(git.gtree(commit_id).blobs[notebook.git_basename].contents)
    end
  end
end
