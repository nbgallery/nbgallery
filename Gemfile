source ENV['GALLERY_GEM_SOURCE'] || 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2'
#gem 'sprockets', '3.6.0' # 3.6.1 breaks all javascript by saying there's a invalid byte sequence
gem 'sprockets', '3.7.2' # 3.7.2 seems ok
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.13', '< 0.5'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc


############################
# Gems for Notebook Gallery
############################

gem 'acts_as_votable'
gem 'bootstrap-sass'
gem 'browser'
gem 'chartkick'
gem 'commontator'
gem 'config'
gem 'devise'
gem 'font-awesome-rails'
gem 'git'
gem 'hightop'
gem 'jquery-datatables-rails'
gem 'jquery-slick-rails'
gem 'metaid'
gem 'net-scp'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-google-oauth2'
gem 'pry-rails'
gem 'puma'
gem 'rack-cors'
gem 'retriable'
gem 'rufus-scheduler'
gem 'slim-rails'
gem 'therubyracer'
gem 'will_paginate-bootstrap'

# API clients
gem 'httmultiparty'
gem 'httparty'
gem 'retryable'

# Error handling
gem 'exception_notification'
gem 'gaffe'

# Scheduled jobs when running under Passenger
# Required explicitly in script/cronic so we can detect when it's active
gem 'cronic', require: false

# Fulltext indexing
gem 'sunspot_rails'
gem 'sunspot_solr'

# Nightly computation - similarities, suggestions, etc.
gem 'activerecord-import'
gem 'nmatrix'
gem 'ranker'
gem 'rmagick'
gem 'tf-idf'

# Instrumentation
gem 'russdeep'

# Notebook rendering
gem 'commonmarker'
gem 'diffy'
gem 'github-markup'
gem 'html-pipeline'
gem 'kramdown'
gem 'mathjax-rails'
gem 'redcarpet'
gem 'rinku'
gem 'rouge'

#Better logging
gem 'lograge'

# Development only
group :development, :test do
  gem 'dotenv'
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'slim_lint', require: false
end

# Load gems from extensions
extension_dirs =
  ENV['GALLERY_EXTENSION_DIRS']&.split(File::PATH_SEPARATOR) ||
  Dir[File.join(File.dirname(__FILE__), '*extensions')]
extension_dirs.each do |dir|
  gemfiles = Dir["#{dir}/Gemfile"] + Dir["#{dir}/*/Gemfile"]
  gemfiles.each do |gemfile|
    eval(File.read(gemfile), nil, gemfile) # rubocop: disable Security/Eval
  end
end
