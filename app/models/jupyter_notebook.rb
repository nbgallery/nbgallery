# Jupyter notebook as an object with some helper methods
class JupyterNotebook
  extend ActiveModel::Naming # for ActiveModel::Errors

  class BadFormat < RuntimeError
  end

  attr_reader :notebook
  attr_reader :errors

  # Create new object from notebook content
  def initialize(content)
    raise JupyterNotebook::BadFormat, 'notebook is empty' if content.blank?
    begin
      @notebook = JSON.parse(content.force_encoding('UTF-8'))
    rescue JSON::ParserError
      raise JupyterNotebook::BadFormat, 'notebook is not valid JSON'
    end
    @errors = ActiveModel::Errors.new(self)
    @text = nil

    version = @notebook.fetch('nbformat', '0').to_i
    raise JupyterNotebook::BadFormat, 'only notebook nbformat 4 is supported' if version < 4

    # Jupyter has two formats.
    # If you download from Jupyter to desktop, source is an array.
    # If you send from Jupyter to Gallery, source is a string.
    # If you upload from desktop to Jupyter, either format is fine.
    # If you send from Gallery to Jupyter, the array format blows up.
    # So, on input to Gallery, convert array to string before storing.
    @notebook['cells'].each do |cell|
      next unless cell.include? 'source'
      cell['source'] = cell['source'].join('') if cell['source'].is_a? Array
    end
  end

  # Convert to git-friendly format
  def to_git_format(tag=nil)
    # Each section in the output has a header with a uuid
    tag ||= SecureRandom.uuid
    header = "# #{tag}"

    # Notebook-level metadata
    output = "#{header} nbformat\n#{self['nbformat']}.#{self['nbformat_minor']}\n"
    output += "#{header} metadata\n#{self['metadata'].to_yaml}\n"

    # Each cell - metadata (if it exists) and source only
    self['cells'].each do |cell|
      output += "#{header} cell metadata\n#{cell['metadata'].to_yaml}\n" if cell['metadata'].present?
      output += "#{header} #{cell['cell_type']}\n#{cell['source']}\n"
    end
    output
  end

  # Convert from git-friendly format
  def self.from_git_format(input)
    # Figure out the uuid header
    header = input[0, input.index(' ', 2)]

    # Output stuff
    jn = {}
    metadata = nil
    nbformat = nil
    cell_metadata = nil

    # Split on the header and handle each section
    r = /#{header} ([a-z ]+)\n/
    input.split(r)[1..-1].each_slice(2) do |type, text|
      text ||= '' # sometimes we lose the final newline through git (?!)
      case type
      when 'nbformat'
        nbformat = text # save for later
      when 'metadata'
        metadata = YAML.safe_load(text) # save for later
      when 'cell metadata'
        cell_metadata = YAML.safe_load(text)
      else
        source = text[0...-1] # strip off added newline at end
        cell = {
          'metadata' => cell_metadata || {},
          'cell_type' => type,
          'source' => source
        }
        if type == 'code'
          cell['execution_count'] = nil
          cell['outputs'] = []
        end
        jn['cells'] ||= []
        jn['cells'] << cell
        cell_metadata = nil
      end
    end

    # Add notebook metadata at the end
    jn['metadata'] = metadata
    major, minor = nbformat.split('.')
    jn['nbformat'] = major.to_i
    jn['nbformat_minor'] = minor.to_i

    # Convert to json text then return new object (which re-parses the json)
    new(jn.to_json)
  end

  # Remove cell outputs
  def strip_output!
    @notebook['cells'].each do |cell|
      cell.delete('attachments')
      next unless cell['cell_type'] == 'code'
      cell['outputs'] = []
      cell['execution_count'] = nil
      cell['metadata']&.delete('ExecuteTime')
    end
    JupyterNotebook.custom_strip_output(self)
    self
  end

  # Remove (most) metadata added by Gallery
  def strip_gallery_meta!
    gallery = @notebook.dig('metadata', 'gallery')
    %w[link clone commit git_commit_id].each {|k| gallery.delete(k)} if gallery
    self
  end

  # Get kernel name
  def kernel
    @notebook.dig('metadata', 'kernelspec', 'name')
  end

  # Spark notebook?
  def spark?
    kernel&.start_with?('spark')
  end

  # Get language and version
  def language
    language = @notebook.dig('metadata', 'language_info', 'name')
    kernel_lang = @notebook.dig('metadata', 'kernelspec', 'language')

    if kernel == 'spark_pyspark'
      %w[python 2]
    elsif kernel == 'spark_sparkr'
      %w[R 3]
    elsif language && language == kernel_lang
      version = @notebook.dig('metadata', 'language_info', 'version')
      [language, version]
    elsif kernel_lang
      name = @notebook.dig('metadata', 'kernelspec', 'display_name') || ''
      m = Regexp.new("#{kernel_lang} ([\\d\\.]+)", Regexp::IGNORECASE).match(name)
      version = m ? m[1] : nil
      [kernel_lang, version]
    else
      ['unknown', nil]
    end
  end

  # Just the notebook json, not this object
  def to_json(*args)
    @notebook.to_json(*args)
  end

  # Semi-pretty-printed json, with newlines but minimal extra space.
  # This helps git handle diffs better (otherwise notebooks are a single line).
  def pretty_json
    JSON.pretty_generate(@notebook, indent: '', space: '')
  end

  # Just the text in 'source' cells
  def text
    if @text.nil?
      @text = []
      @notebook['cells'].each do |cell|
        @text << cell['source'] if cell.include? 'source'
      end
      @text = @text.join("\n")
    end
    @text
  end

  # Just the text in 'source' cells, made pretty for diff
  def text_for_diff
    if @difftext.nil?
      @difftext = []
      @notebook['cells'].each do |cell|
        next unless cell.include?('source')
        @difftext << "#{cell['cell_type']}:\n  #{cell['source'].gsub("\n", "\n  ")}"
      end
      @difftext = @difftext.join("\n\n")
    end
    @difftext
  end

  # Code cells only
  def code_cells
    @notebook['cells'].select {|cell| cell['cell_type'] == 'code' && cell['source'].present?}
  end

  # Code cells - source strings
  def code_cells_source
    code_cells.map {|cell| cell['source']}
  end

  # Defer everything else to the notebook object
  def method_missing(method, *args, &block)
    super unless @notebook.respond_to?(method)
    @notebook.send(method, *args, &block)
  end

  include ExtendableModel

  # Call preprocess_ methods defined here or by extensions
  def preprocess(user)
    processors = methods.select {|m| m.to_s.start_with?('preprocess_')}
    processors.map {|processor| send(processor, user)}.reduce(&:merge)
  end

  # Proposed tags
  def preprocess_proposed_tags(user)
    # Call any propose_tags_ methods.  Each should return a Set.
    proposers = methods.select {|m| m.to_s.start_with?('propose_tags_')}
    proposed = proposers
      .map {|proposer| send(proposer, user)}
      .reduce(&:merge)
      .map {|tag| Tag.normalize(tag)}
      .uniq

    proposed -= GalleryConfig.restricted_tags
    { proposed_tags: proposed }
  end

  # Propose tags from package import patterns
  def propose_tags_from_packages(_user)
    mappings = GalleryConfig.tag_proposal.mappings.to_hash.map {|k, v| [k.to_s, v]}.to_h
    proposed = Set.new
    packages.each do |package|
      proposed.merge(mappings[package]) if mappings[package]
    end
    proposed
  end

  # Propose tags from configured regex
  def propose_tags_from_config(_user)
    return Set.new unless GalleryConfig.tag_proposal.patterns
    patterns = GalleryConfig.tag_proposal.patterns.map {|str| Regexp.new(str)}
    mappings = GalleryConfig.tag_proposal.mappings.to_hash.map {|k, v| [k.to_s, v]}.to_h
    proposed = Set.new
    patterns.each do |pattern|
      text.scan(pattern).flatten.each do |capture|
        proposed.merge(mappings[capture]) if mappings[capture]
      end
    end
    proposed
  end

  # Allows custom stripping of data from notebook
  def self.custom_strip_output(jn)
  end

  # Call validate_ methods defined by extensions
  # Validations may be dependent on the notebook metadata, the user,
  # or request params. (e.g. only certain users can do certain things)
  def valid?(notebook, user, params)
    validators = methods.select {|m| m.to_s.start_with?('validate_')}
    @errors.clear
    validators.each {|validator| send(validator, notebook, user, params)}
    @errors.empty?
  end

  # Convenience method
  def invalid?(notebook, user, params)
    !valid?(notebook, user, params)
  end

  # Parse notebook text for software packages used
  def packages
    func = language[0] == 'c++' ? :cpp : language[0].to_sym
    if PackageGrep.respond_to?(func)
      code_cells_source
        .map {|code| PackageGrep.send(func, code)}
        .flatten
        .uniq
    else
      []
    end
  end

  # For ActiveModel::Errors
  def read_attribute_for_validation(attr)
    send(attr)
  end

  # For ActiveModel::Errors
  def self.human_attribute_name(attr, _options={})
    attr
  end

  # For ActiveModel::Errors
  def self.lookup_ancestors
    [self]
  end

  private

  def respond_to_missing?(name, _include_private=false)
    @notebook.respond_to?(name) or super
  end
end
