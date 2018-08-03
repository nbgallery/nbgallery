# Notebook revision model
class Revision < ActiveRecord::Base
  belongs_to :notebook
  belongs_to :user

  include ExtendableModel

  class << self
    def from_notebook(notebook, revtype, commit_id, user=nil)
      rev = Revision.new(
        notebook: notebook,
        public: notebook.public,
        user: user,
        revtype: revtype,
        commit_id: commit_id
      )
      # If there are visibility-related extension attributes, we want those
      # copied across so we can do visibility permission checking on revisions.
      Notebook.extension_attributes.each do |attr|
        setter = "#{attr}=".to_sym
        rev.send(setter, notebook.send(attr.to_sym)) if rev.respond_to?(setter)
      end
      rev
    end

    def init
      # Create initial revisions for all existing ontebooks
      commit_id = GitRepo.init
      revisions = Notebook.find_each.map do |nb|
        Revision.from_notebook(nb, 'initial', commit_id)
      end
      Revision.import(revisions, batch_size: 500)
    end

    def notebook_commit(revtype, notebook, user, message)
      commit_id = GitRepo.add_and_commit(notebook, message)
      rev = Revision.from_notebook(notebook, revtype, commit_id, user)
      rev.save
      commit_id
    end

    def notebook_create(notebook, user, message)
      notebook_commit('create', notebook, user, message)
    end

    def notebook_update(notebook, user, message)
      notebook_commit('update', notebook, user, message)
    end

    def notebook_delete(notebook, _user, message)
      # On delete, we update git, but we don't create a Revision object
      # since the notebook is no longer in the database.
      GitRepo.add_and_commit(notebook, message, true)
    end

    def notebook_metadata(notebook, user, _message=nil)
      # Metadata changes are reflected in the database but not git.
      # Currently this is only used for visibility changes (public/private).
      # Insert the previous commit_id so we can still grab content from git.
      commit_id = notebook.revisions.last.commit_id
      rev = Revision.from_notebook(notebook, 'metadata', commit_id, user)
      rev.save
    end
  end
end
