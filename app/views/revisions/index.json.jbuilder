json.notebook = [id: @notebook.id, link: notebook_url(@notebook), title: @notebook.title]
json.revisions(@notebook.revisions, partial: 'application/revision_json', as: :revision)
