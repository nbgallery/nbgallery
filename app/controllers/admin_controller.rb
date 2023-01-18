require 'rubygems/package'

# Controller for admin pages
class AdminController < ApplicationController
  before_action :verify_admin

  # GET /admin
  def index
    # Links to other admin pages
    @total_authors = Notebook.includes(:creator).group(:creator).count.count
  end

  # GET /reindex
  def reindex
  end

  # PATCH /admin/group_reindex
  def group_reindex
    Group.reindex
    results = {count: Group.all.count}
    render :json => results
  end

  # PATCH /admin/notebook_reindex
  def notebook_reindex
    results = {}
    results[:finished] = false
    results[:notebook_errors] = []
    results[:count] = 0
    results[:errors] = 0
    limit = params[:limit].blank? ? 500 : params[:limit].to_i
    chunk = params[:page].blank? ? 0 : params[:page].to_i
    # At least one notebook is blocking a full-reindex so doing each notebook individually to find the problem(s)
    Notebook.all.order("id asc").offset(chunk * limit).limit(limit).each do | notebook |
      begin
        notebook.index
        results[:count] += 1
      rescue JupyterNotebook::BadFormat
        results[:errors] += 1
        results[:notebook_errors][results[:notebook_errors].length] = {url: notebook_path(notebook), title: notebook.title, id: notebook.id, uuid: notebook.uuid, text: "Notebook content is missing or corrupt" }
      end
    end
    if (results[:count] + results[:errors]) < limit
      results[:finished] = true
    end
    render :json => results
  end

  # GET /admin/recommender_summary
  def recommender_summary
    @total_notebooks = Notebook.count
    @total_users = User.count
    @total_recommendations = SuggestedNotebook.count
    @notebooks_recommended = SuggestedNotebook.distinct(:notebook_id).count
    @users_with_recommendations = SuggestedNotebook.distinct(:user_id).count

    @reasons = SuggestedNotebook
      .select(reason_select)
      .group(:reason)
      .order('count DESC')

    @most_suggested_notebooks = SuggestedNotebook
      .group(:notebook)
      .order('count_all DESC')
      .limit(50)
      .count

    @users_with_most_suggestions = SuggestedNotebook
      .group(:user)
      .order('count_all DESC')
      .limit(50)
      .count

    @most_suggested_groups = SuggestedGroup
      .group(:group)
      .order('count_all DESC')
      .limit(25)
      .count

    @most_suggested_tags = SuggestedTag.top(:tag, 25)

    @scores = SuggestedNotebook
      .group('notebook_id, user_id')
      .select(:notebook_id, :user_id, 'TRUNCATE(SUM(score), 1) as rounded_score')
      .group_by(&:rounded_score)
      .map {|score, arr| [score, arr.count]}
      .sort_by(&:first)

    @user_notebook_scores = SuggestedNotebook
      .includes(:notebook, :user)
      .select([
        'notebook_id',
        'user_id',
        SuggestedNotebook.reasons_sql,
        SuggestedNotebook.score_sql
      ].join(', '))
      .group('notebook_id, user_id')
      .order('score DESC')
      .limit(25)
  end

  # GET /admin/recommender
  def recommender
    @reason = params[:reason]

    @notebooks = SuggestedNotebook
      .where(reason: @reason)
      .group(:notebook)
      .order('count_all DESC')
      .limit(25)
      .count
    @notebook_count = SuggestedNotebook
      .where(reason: @reason)
      .select(:notebook_id)
      .distinct
      .count

    @users = SuggestedNotebook
      .where(reason: @reason)
      .group(:user)
      .order('count_all DESC')
      .limit(25)
      .count
    @user_count = SuggestedNotebook
      .where(reason: @reason)
      .select(:user_id)
      .distinct
      .count

    # Scores grouped into 0.05-sized bins
    @scores = SuggestedNotebook
      .where(reason: @reason)
      .select('FLOOR(score*20)/20 as rounded_score, count(*) as count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
    @scores = GalleryLib.chart_prep(@scores, keys: (0..20).map {|i| i / 20.0})

    @distribution = SuggestedNotebook
      .where(reason: @reason)
      .select(reason_select)
      .first
  end

  # GET /admin/trendiness
  def trendiness
    @total_notebooks = Notebook.count
    @nonzero_trendiness = NotebookSummary.where('trendiness > 0.0').count

    @scores = NotebookSummary
      .where('trendiness > 0.0')
      .select('FLOOR(trendiness*20)/20 AS rounded_score, COUNT(*) AS count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
    @scores = GalleryLib.chart_prep(@scores, keys: (0..20).map {|i| i / 20.0})

    @notebooks = NotebookSummary
      .includes(:notebook)
      .order(trendiness: :desc)
      .take(25)
      .map(&:notebook)
  end

  # GET /admin/health
  def health
    @execs = exec_helper(nil, false)
    @execs_last30 = exec_helper(nil, true)
    @execs_pass = exec_helper(true, false)
    @execs_pass_last30 = exec_helper(true, true)
    @execs_fail = exec_helper(false, false)
    @execs_fail_last30 = exec_helper(false, true)

    @total_code_cells = CodeCell.count
    @cell_execs = cell_exec_helper(nil, false)
    @cell_execs_fail = @cell_execs - cell_exec_helper(true, false)
    @cell_execs_last30 = cell_exec_helper(nil, true)
    @cell_execs_fail_last30 = @cell_execs_last30 - cell_exec_helper(true, true)

    @total_notebooks = Notebook.count
    @notebook_execs = notebook_exec_helper(nil, false)
    @notebook_execs_fail = @notebook_execs - notebook_exec_helper(true, false)
    @notebook_execs_last30 = notebook_exec_helper(nil, true)
    @notebook_execs_fail_last30 = @notebook_execs_last30 - notebook_exec_helper(true, true)

    @lang_by_day = Execution
      .languages_by_day
      .map {|lang, entries| { name: lang, data: entries }}
    @lang_by_day = GalleryLib.chart_prep(@lang_by_day)

    @users_by_day = Execution.users_by_day

    @success_by_cell_number = execution_success_chart(
      Execution,
      'code_cells.cell_number',
      :cell_number
    )

    @recently_executed = Notebook.recently_executed.limit(20)
    @recently_failed = Notebook.recently_failed.limit(20)

    # Graph with x = fail rate, y = cells with fail rate >= x
    @cumulative_fail_rates = CodeCell.cumulative_fail_rates

    @scores = notebook_health_distribution
  end

  # GET /admin/user_similarity
  def user_similarity
    @scores = similarity_helper(UserSimilarity)
  end

  # GET /admin/user_summary
  def user_summary
    @top_users = UserSummary.includes(:user).order(user_rep_raw: :desc).take(50)
    @top_authors = UserSummary.includes(:user).order(author_rep_raw: :desc).take(50)
  end

  # GET /admin/notebook_similarity
  def notebook_similarity
    @more_like_this = similarity_helper(NotebookSimilarity)
    @users_also_view = similarity_helper(UsersAlsoView)
  end

  # GET /admin/packages
  def packages
    @packages = Notebook.package_summary
  end

  # GET /admin/exception
  def exception
    blah = nil
    render json: blah.stuff
  end

  # GET /admin/notebooks
  def notebooks
    notebooks_info =  Notebook.includes(:creator).group(:creator).count
    total_notebooks = 0
    notebooks_info.each_value do |value|
      total_notebooks += value
    end
    @total_notebooks = total_notebooks
    @total_authors = notebooks_info.count
    @public_count = Notebook.where('public=true').count
    @private_count = Notebook.where('public=false').count
    @notebooks_info = notebooks_info.sort_by {|_user, num| -num}
  end

  # GET /admin/import
  def import
  end

  # POST /admin/import_upload
  def import_upload
    uncompressed = Gem::Package::TarReader.new(Zlib::GzipReader.open(uploaded_archive))
    @import_errors = {}
    @import_warnings = {}
    @successes = []
    text = uncompressed.detect do |f|
      f.full_name == "metadata.json"
    end.read
    if text.empty?
      raise JupyterNotebook::BadFormat, "metadata.json file is missing"
    end
    @metadata = JSON.parse(text, symbolize_names: true)
    uncompressed.rewind
    uncompressed.each do |file|
      next if file.full_name == "metadata.json"
      key = file.full_name.gsub(".ipynb","").to_sym
      @metadata.rehash
      if !validate_import_metadata(@metadata[key],file.full_name)
        next
      end

      creator = User.find_by(:user_name => @metadata[key][:creator])
      updater = User.find_by(:user_name => @metadata[key][:updater])

      jn = JupyterNotebook.new(file.read)
      jn.strip_output!
      jn.strip_gallery_meta!
      staging_id = SecureRandom.uuid
      stage = Stage.new(uuid: staging_id, user: @user)
      stage.content = jn.pretty_json
      if !stage.save
        import_error(file_name, @metadata[key], "Unable to stage the notebook.")
      end
      # Check existence: (owner, title) must be unique
      notebook = Notebook.find_by(uuid: @metadata[key][:uuid]) if !@metadata[key][:uuid].blank?
      if notebook.nil?
        notebook = Notebook.find_or_initialize_by(
          owner: @owner,
          title: Notebook.groom(@metadata[key][:title])
        )
      else
        # Catch UUID being the same but the title changing
        notebook.title = Notebook.groom(@metadata[key][:title])
      end
      new_record=notebook.new_record?
      old_content = notebook.content
      if !new_record
        if @metadata[key][:uuid].nil?
          import_error(file.full_name, @metadata[key],"A notebook with that title for that owner (#{@metadata[key][:owner]}) already exists and the UUID was not specified in the metadata.")
          stage.destroy
          next
        elsif @metadata[key][:uuid] != notebook.uuid
          import_error(file.full_name, @metadata[key],"A notebook with that title for that owner (#{@metadata[key][:owner]}) already exists and the UUID in the metadata (#{@metadata[key][:uuid]}) did not match the UUID in the database (#{notebook.uuid}).")
          stage.destroy
          next
        elsif @metadata[key][:updated].to_datetime < notebook.updated_at.to_datetime
          import_warning(file.full_name, @metadata[key],"The <a href='#{notebook_path(notebook)}'>notebook</a> in the gallery was updated more recently than the uploaded notebook and will not be updated." )
          stage.destroy
          next
        elsif @metadata[key][:updated].to_datetime == notebook.updated_at.to_datetime
          import_warning(file.full_name, @metadata[key],"The <a href='#{notebook_path(notebook)}'>notebook</a> in the gallery appears to have already been udpated to this version and will note be updated.")
          stage.destroy
          next
        end
      else
        notebook.uuid = @metadata[key][:uuid].blank? ? stage.uuid : @metadata[key][:uuid]
        notebook.title = Notebook.groom(@metadata[key][:title])
        notebook.public = !@metadata[key][:public].nil? ? @metadata[key][:public] : params[:visibility]
        notebook.creator = creator
        notebook.owner = @owner
      end
      notebook.lang, notebook.lang_version = jn.language
      imported_tags = []
      default_tags = []
      if !@metadata[key][:tags].nil?
        imported_tags = Tag.from_csv(@metadata[key][:tags].to_csv, user: updater, notebook: notebook)
      end
      default_tags = Tag.from_csv(params[:tags], user: updater, notebook: notebook)
      tags = imported_tags + default_tags + notebook.tags #Don't want to delete tags on import
      invalid_tag=false
      tags.each do |tag|
        if tag.invalid?
          import_error(file_name, @metadata[key],"Found an invalid tag (#{tag.tag_text}) on the notebook. Skipping the notebook.")
          invalid_tag = true
        end
      end
      if invalid_tag
        stage.destroy
        next
      end

      notebook.tags = tags
      notebook.description = @metadata[key][:description] if @metadata[key][:description].present?
      notebook.updater = updater if !updater.nil?
      if (new_record || (stage.content != old_content))
        notebook.content = stage.content # saves to cache
        notebook.commit_id = stage.uuid
        commit_message = "Notebook Imported by Admininistrator"
        if !@metadata[key][:updated].nil?
          notebook.content_updated_at = @metadata[key][:updated].to_datetime
        end
      end
      if !@metadata[key][:created].nil? && new_record
        notebook.created_at = @metadata[key][:created].to_datetime
      end
      if !@metadata[key][:updated].nil?
        notebook.updated_at = @metadata[key][:updated].to_datetime
      end

      # Check validity of the notebook content.
      # This is not done at stage time because validations may depend on
      # user/notebook metadata or request parameters.
      if jn.invalid?(notebook, @owner, params)
        import_error(file_name, @metadata[key],"Notebook is invalid: #{jn.errors}")
        stage.destroy
        next
      end

      if notebook.invalid?
        import_error(file_name, @metadata[key],"Notebook is invalid: #{notebook.errors}")
        stage.destroy
        next
      end

      # Save to the db and to local cache
      if notebook.save
        stage.destroy
        if new_record
          if GalleryConfig.storage.track_revisions
            real_commit_id = Revision.notebook_create(notebook, updater, commit_message)
            revision = Revision.where(notebook_id: notebook.id).last
            if !@metadata[key][:updated].nil?
              revision.updated_at = @metadata[key][:updated].to_datetime
              revision.created_at = @metadata[key][:updated].to_datetime
            end
            revision.save!
          end
          @successes[@successes.length] = { file_name: file.full_name, title: notebook.title, uuid: notebook.uuid, url: notebook_path(notebook), text: "Notebook created", method: "created"}
          if !updater.nil?
            UsersAlsoView.initial_upload(notebook, updater)
            notebook.thread.subscribe(updater)
          end
        else
          method = (notebook.content == old_content ? :notebook_metadata : :notebook_update)
          real_commit_id = Revision.send(method, notebook, updater, commit_message)
          if !updater.nil?
            UsersAlsoView.initial_upload(notebook, updater)
            notebook.thread.subscribe(updater)
          end
          if GalleryConfig.storage.track_revisions
            revision = Revision.where(notebook_id: notebook.id).last
            revision.commit_message = commit_message
            if !@metadata[key][:updated].nil?
              revision.updated_at = @metadata[key][:updated].to_datetime
              revision.created_at = @metadata[key][:updated].to_datetime
            end
            revision.save!
          end
          @successes[@successes.length] = { title: notebook.title, uuid: notebook.uuid, url: notebook_path(notebook), text: "Notebook updated", method: "updated"}
        end
      else
        # We checked validity before saving, so we don't expect to land here, but
        # if we do, we need to rollback the content storage.
        import_error(file_name, @metadata[key],"Failed to save Notebook : #{notebook.errors}")
        notebook.remove_content
        stage.destroy
      end
    end
  end

  # GET /admin/download_export
  def download_export
    @notebooks = Notebook.where('public=true')
    if @notebooks.count > 0
      export_filename = "/tmp/" + SecureRandom.uuid + ".tar.gz"
      metadata = {}
      File.open(export_filename,"wb") do |archive|
        Zlib::GzipWriter.wrap(archive) do |gzip|
          Gem::Package::TarWriter.new(gzip) do |tar|
            @notebooks.each do |notebook|
              metadata[notebook.uuid] = {:updated => notebook.updated_at, :created => notebook.created_at, :title => notebook.title, :description => notebook.description, :uuid => notebook.uuid, :public => notebook.public}
              if notebook.creator
                metadata[notebook.uuid][:creator] = notebook.creator.user_name
              end
              if notebook.updater
                metadata[notebook.uuid][:updater] = notebook.updater.user_name
              end
              if notebook.owner
                if notebook.owner.is_a?(User)
                  metadata[notebook.uuid][:owner] = notebook.owner.user_name
                  metadata[notebook.uuid][:owner_type] = "User"
                else
                  metadata[notebook.uuid][:owner] = notebook.owner.name
                  metadata[notebook.uuid][:owner_type] = "Group"
                end
              end
              if notebook.tags.length > 0
                metadata[notebook.uuid][:tags] = []
                notebook.tags.each do |tag|
                  metadata[notebook.uuid][:tags][metadata[notebook.uuid][:tags].length] = tag.tag_text
                end
              end
              content = notebook.content
              tar.add_file_simple(notebook.uuid + ".ipynb", 0644, content.bytesize) do |io|
                io.write(content)
              end #end tar add_file_simple
            end #End notebooks.each
            tar.add_file_simple("metadata.json", 0644, metadata.to_json.bytesize) do |io|
              io.write(metadata.to_json)
            end #end tar add_file_simple
          end #End TarWriter
        end #End GzipWriter
      end #End File.open
      File.open(export_filename, "rb") do |archive|
        send_data(archive.read, filename: "notebook_export.tar.gz", type: "application/gzip")
      end
      File.unlink(export_filename)
    else
      raise ActiveRecord::RecordNotFound, "No Notebooks Found"
    end
  end

  private

  def reason_select
    [
      'count(1) as count',
      'avg(score) as mean',
      'stddev(score) as stddev',
      'min(score) as min',
      'max(score) as max',
      'reason'
    ].join(', ')
  end

  def exec_helper(success, last30)
    relation = Execution
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('updated_at > ?', 30.days.ago) if last30
    relation.count
  end

  def cell_exec_helper(success, last30)
    relation = Execution
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('executions.updated_at > ?', 30.days.ago) if last30
    relation.select(:code_cell_id).distinct.count
  end

  def notebook_exec_helper(success, last30)
    relation = Execution.joins(:code_cell)
    relation = relation.where(success: success) unless success.nil?
    relation = relation.where('executions.updated_at > ?', 30.days.ago) if last30
    relation.select(:notebook_id).distinct.count
  end

  def similarity_helper(table)
    similarity = table
      .select('ROUND(score*50)/50 AS rounded_score, COUNT(*) AS count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
    GalleryLib.chart_prep(similarity, keys: (0..50).map {|i| i / 50.0})
  end

  def notebook_health_distribution
    # Hash of {:healthy => number of healthy notebooks, etc}
    counts = NotebookSummary
      .where.not(health: nil)
      .map(&:health)
      .group_by {|x| Notebook.health_symbol(x)}
      .map {|sym, vals| [sym, vals.size]}
      .to_h
    # Histogram of scores in 0.05-sized bins
    scores = NotebookSummary
      .where.not(health: nil)
      .select('FLOOR(health*40)/40 AS rounded_score, COUNT(*) AS count')
      .group('rounded_score')
      .map {|result| [result.rounded_score, result.count]}
      .group_by {|score, _count| Notebook.health_symbol(score + 0.01)}
      .map {|sym, data| { name: "#{sym} (#{counts[sym]})", data: data }}
    GalleryLib.chart_prep(scores, keys: (0..40).map {|i| i / 40.0})
  end

  def uploaded_archive
    if params[:file].nil?
      [request.body.read, nil]
    else
      unless params[:file].respond_to?(:tempfile) && params[:file].respond_to?(:original_filename)
        raise JupyterNotebook::BadFormat, 'Expected a file object.'
      end
      unless params[:file].original_filename.end_with?('.tar.gz')
        raise JupyterNotebook::BadFormat, 'File extension must be .tar.gz'
      end
      params[:file].tempfile
    end
  end

  def import_error(file_name, metadata, error)
    if @import_errors[file_name].nil?
      @import_errors[file_name] = []
    end
    @import_errors[file_name][@import_errors[file_name].length] = {metadata: metadata, text: error}
  end
  def import_warning(file_name, metadata, error)
    if @import_warnings[file_name].nil?
      @import_warnings[file_name] = []
    end
    @import_warnings[file_name][@import_warnings[file_name].length] = {metadata: metadata, text: error}
  end

  def validate_import_metadata(metadata,file_name)
    valid = true
    if metadata.nil?
      import_error(file_name, metadata,"No metaddata specified for the file.")
      valid = false
    else
      if metadata[:title].blank?
        import_error(file_name, metadata,"No title specified.")
        valid = false
      end
      if metadata[:owner].blank?
        import_error(file_name, metadata,"No Owner username specified.")
        valid = false
      end
      if metadata[:owner_type].blank? || (metadata[:owner_type] != 'User' && metadata[:owner_type] != 'Group')
        import_error(file_name, metadata,"Invalid owner type (#{metadata[:owner_type]}) in metadata (expected 'User' or 'Group' ).")
        valid = false
      else
        if metadata[:owner_type] == 'User'
          @owner = User.find_by(:user_name => metadata[:owner])
        elsif metadata[:owner_type] == 'Group'
          @owner = Group.find_by(:name => metadata[:owner])
        end
        if @owner.nil?
          import_error(file_name, metadata,"Owner (#{metadata[:owner]}) not found in the database.")
          valid = false
        end
      end
    end
    valid
  end
end
