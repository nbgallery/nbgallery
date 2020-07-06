# Notebook model
class Notebook < ActiveRecord::Base
  belongs_to :owner, polymorphic: true
  belongs_to :creator, class_name: 'User', inverse_of: 'notebooks_created'
  belongs_to :updater, class_name: 'User', inverse_of: 'notebooks_updated'
  has_one :notebook_summary, dependent: :destroy, autosave: true
  has_many :notebook_dailies, dependent: :destroy
  has_many :change_requests, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :clicks, dependent: :destroy
  has_many :notebook_similarities, dependent: :destroy
  has_many :users_also_views, dependent: :destroy
  has_many :keywords, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_and_belongs_to_many :shares, class_name: 'User', join_table: 'shares'
  has_and_belongs_to_many :stars, class_name: 'User', join_table: 'stars'
  has_many :code_cells, dependent: :destroy
  has_many :executions, through: :code_cells
  has_many :execution_histories, dependent: :destroy
  has_many :revisions, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :subscriptions, as: :sub, dependent: :destroy
  has_one :deprecated_notebook

  acts_as_commontable # dependent: :destroy # requires commontator 5.1

  validates :uuid, :title, :description, :owner, presence: true
  validates :title, format: { with: /\A[^:\/\\]+\z/, message: 'must not contain a colon, forward-slash or back-slash (:/\\)' }
  validates :public, not_nil: true
  validates :uuid, uniqueness: { case_sensitive: false }
  validates :uuid, uuid: true

  after_destroy :remove_content, :remove_wordcloud

  searchable do # rubocop: disable Metrics/BlockLength
    # For permissions...
    boolean :public
    string :owner_type
    integer :owner_id
    integer :shares, multiple: true do
      shares.pluck(:id)
    end

    # For sorting...
    time :updated_at
    time :created_at
    string :title do
      Notebook.groom(title).downcase
    end
    # Note: tried to join to NotebookSummary for these, but sorting didn't work
    integer :views do
      num_views
    end
    integer :stars do
      num_stars
    end
    integer :runs do
      num_runs
    end
    integer :downloads do
      num_downloads
    end
    float :health
    float :trendiness

    # For searching...
    integer :id
    text :lang
    text :title, stored: true, more_like_this: true do
      Notebook.groom(title)
    end
    text :body, stored: true, more_like_this: true do
      notebook.text rescue ''
    end
    text :tags do
      tags.pluck(:tag)
    end
    text :description, stored: true, more_like_this: true
    text :owner do
      owner.is_a?(User) ? owner.user_name : owner.name
    end
    text :owner_description do
      owner.is_a?(User) ? owner.name : owner.description
    end
    text :creator do
      creator.user_name
    end
    text :creator_description do
      creator.name
    end
    text :updater do
      updater.user_name
    end
    text :updater_description do
      updater.name
    end
    string :package, :multiple => true do
      notebook.packages.map { |package| package}
    end
    #deprecation status
    boolean :active do
      deprecated_notebook == nil
    end
  end

  # Sets the max number of notebooks per page for pagination
  self.per_page = 20

  attr_accessor :fulltext_snippet
  attr_accessor :fulltext_score
  attr_accessor :fulltext_reasons

  extend Forwardable

  # Exception for uploads with bad parameters
  class BadUpload < RuntimeError
    attr_reader :errors

    def initialize(message, errors=nil)
      super(message)
      @errors = errors
    end

    def message
      msg = super
      if errors
        msg + ': ' + errors.full_messages.join('; ')
      else
        msg
      end
    end
  end

  # Constructor
  def initialize(*args, &block)
    super(*args, &block)
    # Go ahead and create a default summary
    self.notebook_summary = NotebookSummary.new(
      views: 1,
      unique_views: 1,
      trendiness: 1.0
    )
    self.content_updated_at = Time.current
  end


  #########################################################
  # Extension points
  #########################################################

  include ExtendableModel

  # Cleans up a string for display
  def self.groom(str)
    str
  end

  # Custom permissions for notebook read
  def self.custom_permissions_read(_notebook, _user, _use_admin=false)
    true
  end

  # Custom permissions for notebook edit
  def self.custom_permissions_edit(_notebook, _user, _use_admin=false)
    true
  end

  # Custom permission checking for mysql query
  def self.custom_permissions_sql(relation, _user, _use_admin=false)
    relation
  end

  # Custom permission checking for solr fulltext query
  def self.custom_permissions_solr(_user)
    proc do
    end
  end

  #########################################################
  # Database helpers
  #########################################################

  # Helper function to join things with a permissions clause
  # Tip: if 'thing' is based on another class instead of Notebook, you'll
  # probably need to have .joins(:notebook) in it.
  def self.readable_join(thing, user, use_admin=false)
    relation =
      if user.member?
        thing
          .joins("LEFT OUTER JOIN shares ON (shares.notebook_id = notebooks.id AND shares.user_id = #{user.id})")
          .where(
            '(public = 1) OR ' \
            "(owner_type = 'User' AND owner_id = ?) OR " \
            "(owner_type = 'Group' AND owner_id IN (?)) OR " \
            '(shares.user_id = ?) OR ' \
            '(?)',
            user.id,
            user.groups.pluck(:id),
            user.id,
            (use_admin && user.admin?)
          )
      else
        thing.where('(public = 1)')
      end
    custom_permissions_sql(relation, user, use_admin)
  end

  # Scope that returns all notebooks readable by the given user
  def self.readable_by(user, use_admin=false)
    readable_join(Notebook, user, use_admin)
  end

  # Readable joined with summary + suggestions.
  # This is used so we can sort by notebook fields as well as
  # suggestion score, num views/stars/runs.
  def self.readable_megajoin(user, use_admin=false)
    # Get the name of the suggested_notebooks -> user_id foreign key
    @suggested_notebooks_user_id_fk ||= SuggestedNotebook
      .connection
      .foreign_keys(:suggested_notebooks)
      .select {|fk| fk.from_table == :suggested_notebooks && fk.to_table == 'users'}
      .first
      &.options
      &.dig(:name)

    relation = readable_by(user, use_admin)
      .joins('JOIN notebook_summaries ON (notebook_summaries.notebook_id = notebooks.id)')

    # Sometimes MySQL chooses the wrong index for this join and the query is very slow
    hint = ''
    hint = "USE INDEX (#{@suggested_notebooks_user_id_fk})" if @suggested_notebooks_user_id_fk
    prefix = "LEFT OUTER JOIN suggested_notebooks #{hint} ON (suggested_notebooks.notebook_id = notebooks.id"
    relation =
      if user.member?
        relation.joins(prefix + " AND suggested_notebooks.user_id = #{user.id})")
      else
        relation.joins(prefix + ' AND suggested_notebooks.user_id IS NULL)')
      end

    # Notebooks with no health score get default 0.5 for "unknown"
    # Health is scaled to [-1, 1] for overall score to penalize unhealthy notebooks.
    score_str = '(IF(SUM(score), SUM(score), 0.0) + trendiness + IF(review, review, 0.0) + ' \
      'IF(health IS NOT NULL, 2.0 * health - 1.0, 0.0)) AS score'
    relation
      .select([
        'notebooks.*',
        'views',
        'stars',
        'runs',
        'downloads',
        'IF(health IS NOT NULL, health, 0.5) AS health',
        'trendiness',
        SuggestedNotebook.reasons_sql,
        'IF(SUM(score), SUM(score), 0.0) as recscore',
        score_str
      ].join(', '))
      .group('notebooks.id')
  end

  # Helper function to join things with a permissions clause
  def self.editable_join(thing, user, use_admin=false)
    relation = thing
      .joins("LEFT OUTER JOIN shares ON (shares.notebook_id = notebooks.id AND shares.user_id = #{user.id})")
      .where(
        "(owner_type = 'User' AND owner_id = ?) OR " \
        "(owner_type = 'Group' AND owner_id IN (?)) OR " \
        '(shares.user_id = ?) OR ' \
        '(?)',
        user.id,
        user.groups_editor.pluck(:id),
        user.id,
        (use_admin && user.admin?)
      )
    custom_permissions_sql(relation, user, use_admin)
  end

  # Scope that returns all notebooks editable by the given user
  def self.editable_by(user, use_admin=false)
    editable_join(Notebook, user, use_admin)
  end

  # Language => count for the given user
  def self.language_counts(user)
    languages = Notebook.readable_by(user).group(:lang).count.map {|k, v| [k, nil, v]}
    python2 = Notebook.readable_by(user).where(lang: 'python').where("lang_version LIKE '2%'").count
    python3 = Notebook.readable_by(user).where(lang: 'python').where("lang_version LIKE '3%'").count
    languages += [['python', '2', python2], ['python', '3', python3]]
    languages.sort_by {|lang, _version, _count| lang.downcase}
  end

  # Get user-specific notebook boosts based on recommendations, health, etc
  def self.fulltext_boosts(user)
    boosts = except(:includes).readable_megajoin(user).order('score DESC').limit(100)
    boosts = boosts.map do |nb|
      scores = [
        "boost=#{format('%4.2f', nb.attributes['score'] || 0)}",
        "rec=#{format('%4.2f', nb.attributes['recscore'] || 0)}",
        "h=#{format('%4.2f', nb.attributes['health'] || 0)}",
        "t=#{format('%4.2f', nb.attributes['trendiness'] || 0)}",
        "r=#{format('%4.2f', nb.attributes['review'] || 0)}"
      ]
      if nb.score < 0
        nb.score = 0
      end
      [nb.id, { reasons: nb.reasons, score: nb.score || 0, boosts: scores.join('/') }]
    end
    boosts.to_h
  end

  # Permissions logic for queries to SOLR
  def self.solr_permissions(user, use_admin=false)
    proc do
      unless use_admin
        all_of do
          any_of do
            with(:public, true)
            with(:shares, user.id)
            all_of do
              with(:owner_type, 'User')
              with(:owner_id, user.id)
            end
            groups = user.groups.pluck(:id)
            if groups.present?
              all_of do
                with(:owner_type, 'Group')
                with(:owner_id, groups)
              end
            end
          end
          instance_eval(&Notebook.custom_permissions_solr(user))
        end
      end
    end
  end

  # Full-text search scoped by readability
  def self.fulltext_search(text, user, opts={})
    page = opts[:page] || 1
    sort = opts[:sort] || :score
    sort_dir = opts[:sort_dir] || :desc
    use_admin = opts[:use_admin].nil? ? false : opts[:use_admin]
    # Remove keywords out of the text search (such as Lang:Python)
    filtered_text = text.split(/\s(?=(?:[^"]|"[^"]*"|[^:]+:"[^"]*")*$)/).reject{ |w| w =~ /[^:]+:.*+/}.join(" ")
    # Create array of all of the keywords for search
    keywords = text.split(/\s(?=(?:[^"]|"[^"]*"|[^:]+:"[^"]*")*$)/).select{ |w| w =~ /[^:]+:[^:]+/}
    search_fields = {}
    # These are the fields we will allow advanced searching on (all are actual fields except user, which we are aliasing to owner, creator or updater)
    allowed_fields = ["owner","creator","updater","description","tags","lang","title","user","package","active"]
    keywords.each do |keyword|
      temp=keyword.split(":")
      if (allowed_fields.include? temp[0])
        if search_fields[temp[0]] == nil
          search_fields[temp[0]] = Array.new
        end
        # Build a hash of arrays containing all of the values for a field
        search_fields[temp[0]].push(temp[1])
      else
        # Not an allowed keyword, just shove it back in the regular fulltext-search string
        filtered_text = filtered_text + " " + temp[0] + " " + temp[1]
      end
    end
    boosts = fulltext_boosts(user)
    sunspot = Notebook.search do
      fulltext(filtered_text, highlight: true) do
        boost_fields title: 50.0, description: 10.0, owner: 15.0, owner_description: 15.0
        boosts.each {|id, info| boost((info[:score] || 0) * 5.0) {with(:id, id)}}
      end
      search_fields.each do |field,values|
        if(field == "package")
          values.each do |value|
            if(value =~ /^-/)
              without(:package,value[1..-1])
            else
              with(:package,value)
            end
          end
        elsif(field == "active")
          if(values.join(" ")  == "true")
            with(:active,true)
          else
            with(:active,false)
          end
        else
          fulltext(values.join(" ")) do
            if(field == "user")
              fields(:owner, :creator, :updater)
            else
              fields(field)
            end
          end
        end
      end
      instance_eval(&Notebook.solr_permissions(user, use_admin))
      order_by sort, sort_dir
      paginate page: page, per_page: per_page
    end
    sunspot.hits.each do |hit|
      hit.result.fulltext_hit(hit, user, boosts)
    end
    sunspot.results
  end

  def fulltext_hit(hit, user, boosts)
    self.fulltext_snippet = hit.highlights.map(&:format).join(' ... ')
    if user.admin? && hit.score
      score_text = "score=#{format('%.2f', hit.score)}"
      boost_text = boosts.dig(hit.result.id, :boosts) || 'boost=0.0'
      self.fulltext_snippet += " [#{score_text} #{boost_text}]"
    end
    self.fulltext_score = hit.score
    self.fulltext_reasons = boosts.dig(hit.result.id, :reasons)
  end

  def self.get(user, opts={})
    if opts[:q]
      includes(:creator, { updater: :user_summary }, :owner, :tags, :notebook_summary)
        .fulltext_search(opts[:q], user, opts)
    else
      page = opts[:page] || 1
      sort = opts[:sort] || :score
      sort_dir = opts[:sort_dir] || :desc
      use_admin = opts[:use_admin].nil? ? false : opts[:use_admin]

      order =
        if %i[stars views runs downloads score health trendiness].include?(sort)
          "#{sort} #{sort_dir.upcase}"
        else
          "notebooks.#{sort} #{sort_dir.upcase}"
        end

      readable_megajoin(user, use_admin)
        .includes(:creator, { updater: :user_summary }, :owner, :tags, :notebook_summary)
        .order(order)
        .paginate(page: page)
    end
  end

  # Notebooks with high user view overlap, filtered by permissions
  def users_also_viewed(user, use_admin=false)
    other = users_also_views
      .includes(:other_notebook)
      .joins('JOIN notebooks ON notebooks.id = users_also_views.other_notebook_id')
    Notebook.readable_join(other, user, use_admin).order(score: :desc)
  end

  # Notebooks similar to this one, filtered by permissions
  def similar_for(user, use_admin=false)
    similar = notebook_similarities
      .includes(:other_notebook)
      .joins('JOIN notebooks ON notebooks.id = notebook_similarities.other_notebook_id')
    Notebook.readable_join(similar, user, use_admin).order(score: :desc)
  end

  # Notebooks similar to this one, filtered by permissions
  def more_like_this(user, opts={})
    page = opts[:page] || 1
    per_page = opts[:per_page] || opts[:count] || Notebook.per_page
    use_admin = opts[:use_admin].nil? ? false : opts[:use_admin]

    ids =
      begin
        sunspot = Sunspot.more_like_this(self) do
          instance_eval(&Notebook.solr_permissions(user, use_admin))
          paginate page: page, per_page: per_page
        end
        sunspot.hits.map(&:primary_key)
      rescue StandardError => e
        Rails.logger.error("Solr error: #{e}")
        []
      end
    notebooks = Notebook.where(id: ids)
    # FIELD sort to retain the order returned by solr
    notebooks = notebooks.order("FIELD(id,#{ids.join(',')})") if ids.present?
    notebooks
  end

  # Partial snippet from recommendation reasons
  def recommendation_snippet
    if fulltext_reasons
      "<em>#{fulltext_reasons.capitalize}</em>"
    elsif respond_to?(:reasons) && reasons
      "<em>#{reasons.capitalize}</em>"
    end
  end

  # Snippet from fulltext and/or suggestions
  def snippet(user)
    highlights = GalleryLib.escape_highlight(fulltext_snippet)
    recommendations = recommendation_snippet
    snippet =
      if highlights && recommendations
        "#{highlights}<br>#{recommendations}"
      elsif highlights
        highlights
      elsif recommendations
        recommendations
      else
        ''
      end
    show_score = (user.admin? && respond_to?(:score) && score && score >= 0.0)
    snippet += " <em>[#{format('%.4f', score)}]</em>" if show_score
    snippet
  end

  # Helper for custom read permissions
  def custom_read_check(user, use_admin=false)
    Notebook.custom_permissions_read(self, user, use_admin)
  end

  # Helper for custom edit permissions
  def custom_edit_check(user, use_admin=false)
    Notebook.custom_permissions_edit(self, user, use_admin)
  end

  # List of revisions that the user can see
  def revision_list(user, options={})
    # Only return revisions back until the most recent one the user can't see
    # unless stop_at_private is set to false.
    # For example if the nb was public then private then public, the user can't
    # see revisions from the first public time period, only the recent period,
    # unless stop_at_private option is set to false.
    use_admin = options[:use_admin] || false
    max = options[:max]
    exclude_metadata = options[:exclude_metadata] || false
    stop_at_private = options[:stop_at_private] || true
    allowed = []
    revisions.order(created_at: :desc).each do |rev|
      break unless !stop_at_private || user.can_read_revision?(rev, use_admin)
      allowed << rev unless exclude_metadata && rev.revtype == 'metadata'
      break if max && allowed.count >= max
    end
    allowed
  end

  # Map of commit_id => revision for revisions the user can see
  def revision_map(user, use_admin=false)
    revision_list(user, use_admin: use_admin)
      .reject {|rev| rev.revtype == 'metadata'}
      .map {|rev| [rev.commit_id, rev]}
      .to_h
  end

  # Does notebook have a recent review of this type?
  def recent_review?(revtype)
    reviews.where(revtype: revtype, status: 'completed').last&.recent?
  end


  #########################################################
  # Raw content methods
  #########################################################

  # Location on disk
  def basename
    "#{uuid}.ipynb"
  end

  # Location on disk
  def filename
    File.join(GalleryConfig.directories.cache, basename)
  end

  # Git version basename
  def git_basename
    "#{uuid}.txt"
  end

  # Git version full filename
  def git_filename
    File.join(GalleryConfig.directories.repo, git_basename)
  end

  # Write out the git-friendly version
  def save_git_version
    File.write(git_filename, notebook.to_git_format(uuid))
  end

  # The raw content from the file cache
  def content
    File.read(filename, encoding: 'UTF-8') if File.exist?(filename)
  end

  # The JSON-parsed notebook from the file cache
  def notebook
    JupyterNotebook.new(content)
  end

  # Set new content in file cache and repo
  def content=(content)
    # Save to cache and update hashes
    File.write(filename, content)
    rehash

    # Update modified time in database
    self.content_updated_at = Time.current
  end

  # Save new version of notebook
  def notebook=(notebook_obj)
    self.content = notebook_obj.pretty_json
  end

  # Remove the cached file
  def remove_content
    File.unlink(filename) if File.exist?(filename)
  end

  # Size on disk
  def size_on_disk
    File.exist?(filename) ? File.size(filename) : 0
  end


  #########################################################
  # Tag methods
  #########################################################

  # Add a tag (applied by user) to this notebook
  def add_tag(tag, user=nil)
    return unless tags.where(tag: tag).empty?
    tag = Tag.new(tag: tag, user: user, notebook: self)
    tags.push(tag) if tag.valid?
  end

  # Remove a tag from this notebook
  def remove_tag(tag)
    tags.where(tag: tag).destroy_all
  end

  # Set tags to the specified list
  def set_tags(tag_list, user=nil)
    tags.destroy_all
    tag_list.each {|tag| add_tag(tag, user)}
  end

  # Is notebook trusted?
  def trusted?
    !tags.where(tag: 'trusted').empty?
  end


  #########################################################
  # Click methods
  #########################################################

  # Delegate count methods to summary object
  NotebookSummary.attribute_names.each do |name|
    next if name == 'id' || name.end_with?('_id', '_at')
    if %w[health trendiness].include?(name)
      def_delegator :notebook_summary, name.to_sym, name.to_sym
    else
      def_delegator :notebook_summary, name.to_sym, "num_#{name}".to_sym
    end
  end

  def compute_trendiness
    dailies = notebook_dailies.where('day >= ?', 30.days.ago.to_date).pluck(:daily_score)
    if !dailies.empty?
      value = dailies.max
      nb_age = ((Time.current - created_at) / 1.month).to_i
      age_penalty = [nb_age * 0.05, 0.25].min
      value *= (1.0 - age_penalty)
      [value.round(2), 0.01].max
    else
      0.0
    end
  end

  def trendiness=(value)
    notebook_summary.update(trendiness: value)
  end

  def metrics
    metrics = {}
    NotebookSummary.attribute_names.each do |name|
      next if name == 'id' || name.end_with?('_id', '_at')
      metrics[name.to_sym] = notebook_summary.send(name.to_sym)
    end
    metrics[:edit_history_count] = edit_history.count
    metrics
  end

  # Enumerable list of notebook views
  def all_viewers
    clicks.where(action: 'viewed notebook')
  end

  def unique_click_helper(users)
    users
      .includes(:user)
      .select('user_id, COUNT(*) AS count, MAX(updated_at) AS last')
      .group(:user_id)
      .map {|c| [c.user, { count: c.count, last: c.last }]}
      .to_h
  end

  # Map of User => num views
  def unique_viewers
    unique_click_helper(all_viewers)
  end

  # Enumerable list of notebook downloads
  def all_downloaders
    clicks.where(action: 'downloaded notebook')
  end

  # Map of User => num downloads
  def unique_downloaders
    unique_click_helper(all_downloaders)
  end

  # Enumerable list of notebook runs
  def all_runners
    clicks.where(action: 'ran notebook')
  end

  # Map of User => num runs
  def unique_runners
    unique_click_helper(all_runners)
  end

  # Enumerable list of notebook executions (as recorded in clickstream)
  def all_executors
    clicks.where(action: 'executed notebook')
  end

  # Map of User => num executions (as recorded in clickstream)
  def unique_executors
    unique_click_helper(all_executors)
  end

  # Edit history
  def edit_history
    clicks.where(action: ['created notebook', 'edited notebook']).order(created_at: :desc)
  end


  #########################################################
  # Instrumentation
  #########################################################

  # Rehash this notebook
  def rehash
    self.code_cells = notebook.code_cells_source.each_with_index.map do |source, i|
      CodeCell.new(
        notebook: self,
        cell_number: i,
        md5: Digest::MD5.hexdigest(source),
        ssdeep: Ssdeep.from_string(source)
      )
    end
  end

  # Rehash all notebooks
  def self.rehash
    Notebook.find_each(&:rehash)
  end

  include Notebooks::HealthFunctions


  #########################################################
  # Misc methods
  #########################################################

  include Notebooks::WordcloudFunctions

  # User-friendly URL /notebooks/id-title-here
  def to_param
    "#{id}-#{Notebook.groom(title).parameterize}"
  end

  # Owner id string
  def owner_id_str
    owner.is_a?(User) ? owner.user_name : owner.gid
  end

  # Owner email
  def owner_email
    if owner.is_a?(User)
      [owner.email]
    else
      owner.editors.pluck(:email)
    end
  end

  # Counts of packages by language
  # Returns hash[language][package] = count
  def self.package_summary
    results = {}
    by_lang = find_each
      .map {|notebook| [notebook.lang, notebook.notebook.packages]}
      .group_by {|lang, _packages| lang}

    by_lang.each do |lang, entries|
      results[lang] = entries
        .map(&:last)
        .flatten
        .group_by {|package| package}
        .map {|package, packages| [package, packages.size]}
        .to_h
    end

    results
  end
end
