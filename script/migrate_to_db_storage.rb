def migrate_notebook(notebook)
  notebookFile = NotebookFile.where(notebook_id: notebook.id, save_type:"notebook", uuid: notebook.uuid).first
  if notebookFile.nil?
    notebookFile  = NotebookFile.new
    notebookFile.notebook_id = notebook.id * 1
    notebookFile.save_type = "notebook"
    notebookFile.uuid = notebook.uuid
  end
  if notebook.content.blank?
    print "Notebook File Missing, Aborting migration\n"
  else
    notebookFile.content = notebook.content
    notebookFile.save
    if GalleryConfig.storage.track_revisions
      notebook.revisions.each do | revision |
        print "\tMigratiing Revision #{revision.commit_id}\n"
        migrate_revision(notebook, revision)
      end
    end
  end
end

def migrate_revision(notebook, revision)
  begin
    notebookFile = NotebookFile.where(notebook_id: notebook.id, revision_id: revision.id, save_type:"revision", uuid: revision.commit_id).first
    if notebookFile.nil?
      notebookFile  = NotebookFile.new
      notebookFile.notebook_id = notebook.id
      notebookFile.revision_id = revision.id
      notebookFile.save_type = "revision"
      notebookFile.uuid = notebook.uuid
    else
      print "Already existsed?"
    end
    notebookFile.content = revision.content.to_git_format(revision.commit_id)
    #print "Content #{notebookFile.content}"
    notebookFile.save!
  rescue NoMethodError
    print "\tERROR: Revision is not a valid notebook #{revision.commit_id}\n"
  rescue Git::GitExecuteError
    print "\tERROR: Revision missing from database #{revision.commit_id}\n"
  end
end

def migrate_staging
end

def migrate_change_request
end

GalleryConfig.storage.notebook_file_class = false

notebooks = Notebook.all

notebooks.each do | notebook |
  print "Migrating #{notebook.title}\n"
  migrate_notebook(notebook)
end
