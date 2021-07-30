def migrate_notebook(notebook)
  notebookFile = NotebookFile.find_or_initialize_by(notebook_id: notebook.id, save_type:"notebook", uuid: notebook.uuid)
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
    notebookFile = NotebookFile.find_or_initialize_by(revision_id: revision.id, save_type:"revision", uuid: notebook.uuid)
    notebookFile.content = revision.content.to_json
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
      notebookFile = NotebookFile.find_or_initialize_by(stage_id: staged_notebook.id, save_type:"stage", uuid: staged_notebook.uuid)
      notebookFile.content = stage.content
      notebookFile.save!
    end
  end
end

def migrate_change_request
  change_requests = ChangeRequest.all
  if !change_requests.nil?
    change_requests.each do | change_request |
      if (change_request.status == "pending" || change_request.status == "declined")
        print "Migrating Change Request #{change_request.reqid}\n"
        notebookFile = NotebookFile.find_or_initialize_by(change_request_id: change_request.id, save_type:"change_request", uuid: change_request.reqid)
        notebookFile.content = change_request.proposed_content
        notebookFile.save!
      end
    end
  end
end

GalleryConfig.storage.database_notebooks = false

notebooks = Notebook.all

notebooks.each do | notebook |
  print "Migrating #{notebook.title}\n"
  migrate_notebook(notebook)
end
migrate_change_request()
