def migrate_notebook(notebook)
  notebookFile = NotebookFile.where(notebook_id: notebook.id, save_type:"notebook", uuid: notebook.uuid).first
  if notebookFile.nil?
    notebookFile  = NotebookFile.new
    notebookFile.notebook_id = notebook.id
    notebookFile.save_type = "notebook"
    notebookFile.uuid = notebook.uuid
  end
  if notebook.content.blank?
    print "\tError: Notebook File Missing, Aborting migration\n"
  else
    notebookFile.content = notebook.content
    notebookFile.save
    if GalleryConfig.storage.track_revisions
      notebook.revisions.each do | revision |
        migrate_revision(notebook, revision)
      end
    end
  end
end

def migrate_revision(notebook, revision)
  begin
    notebookFile = NotebookFile.where(revision_id: revision.id, save_type:"revision", uuid: notebook.uuid).first
    if notebookFile.nil?
      notebookFile  = NotebookFile.new
      notebookFile.revision_id = revision.id
      notebookFile.save_type = "revision"
      notebookFile.uuid = notebook.uuid
    end
    notebookFile.content = revision.content.to_git_format(revision.commit_id)
    notebookFile.save!
  rescue NoMethodError
    print "\tERROR: Revision is not a valid notebook #{revision.commit_id}\n"
  rescue Git::GitExecuteError
    print "\tERROR: Revision missing from database #{revision.commit_id}\n"
  end
end

def migrate_staging
  staged_notebooks = Stage.all
  if !staged_notebooks.nil?
    staged_notebooks.each do | staged_notebook |
      notebookFile = NotebookFile.where(stage_id: staged_notebook.id, save_type:"staged", uuid: staged_notebook.uuid).first
      if notebookFile.nil?
        notebookFile  = NotebookFile.new
        notebookFiles.stage_id = staged_notebook.id
        notebookFile.save_type = "stage"
        notebookFile.uuid = staged_notebook.uuid
      end
      notebookFile.content = stage.content
      notebookFile.save!
    end
  end
end

def migrate_change_request
  change_requests = ChangeRequest.all
  if !change_requests.nil?
    change_requests.each do | change_request |
      notebookFile = NotebookFile.where(change_request_id: change_request.id, save_type:"change_request", uuid: change_request.notebook.uuid).first
      if notebookFile.nil?
        notebookFile  = NotebookFile.new
        notebookFiles.change_request_id = change_request.id
        notebookFile.save_type = "change_request"
        notebookFile.uuid = change_request.notebook.uuid
      end
      notebookFile.content = change_request.proposed_content
      notebookFile.save!
    end
  end
end

GalleryConfig.storage.notebook_file_class = false

notebooks = Notebook.all

notebooks.each do | notebook |
  print "Migrating #{notebook.title}\n"
  migrate_notebook(notebook)
end
