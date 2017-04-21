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
    rescue
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

  # Remove cell outputs
  def strip_output!
    @notebook['cells'].each do |cell|
      if cell['cell_type'] == 'code'
        cell['outputs'] = []
        cell['execution_count'] = nil
      end
    end
    self
  end

  # Remove metadata added by Gallery
  def strip_gallery_meta!
    @notebook['metadata']['gallery'] = {} if
      @notebook.include?('metadata') && @notebook['metadata'].include?('gallery')
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
    elsif language
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
  def to_json
    @notebook.to_json
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
    func = language[0] == 'c++' ? :cpp_packages : "#{language[0]}_packages".to_sym
    if respond_to?(func)
      send(func)
    else
      []
    end
  end

  # Package helper for ruby notebooks
  def ruby_packages
    patterns = [
      # require 'package'
      /^\s*require\s+["']([^"']{1,50})["']/m,
      # iruby-dependencies:
      #   gem 'package'
      #   gem 'package', require 'module'
      /^\s*gem\s+["']([^"']{1,50})["'](?:[^\n\r]{0,100}require:\s*["']([^"']{1,50})["'])?/m
    ]
    patterns
      .flat_map {|pattern| text.scan(pattern).flatten}
      .reject(&:nil?)
      .uniq
  end

  # Package helper for ruby notebooks
  def python_packages
    # Handle 'import a as b, x as y, ...'
    imports = text
      .scan(/^\s*import\s+([\w ,]{1,100})(?:#|$)/m)
      .flatten
      .flat_map {|capture| capture.split(',').map {|p| p.split.first}}

    # Handle ipydeps.pip('package') and ipydeps.pip(['p1', 'p2', ...])
    ipydeps = text
      .scan(/^\s*ipydeps.pip\s*\(([^\)]{1,100})\)/m)
      .flatten
      .flat_map {|capture| capture.scan(/\w+/)}

    # Other patterns
    patterns = [
      # from package import thing
      /^\s*from\s+(\S{1,50})\s+import/m,
      # pip.main(['install', 'package'])
      /^\s*pip.main\s*\(\s*\[["']install["'],\s*["']([^"']{1,50})["']/m
    ]
    other = patterns
      .flat_map {|pattern| text.scan(pattern).flatten}
      .reject(&:nil?)

    (imports + ipydeps + other).uniq
  end

  # Package helper for R notebooks
  def R_packages # rubocop: disable Style/MethodName
    text.scan(/^\s*library\((\w+)\)/).flatten.uniq
  end

  # Package helper for C++ notebooks
  def cpp_packages
    text.scan(/^\s*#include <(\w+)>/).flatten.uniq
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
