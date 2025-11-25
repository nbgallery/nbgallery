source ENV['GALLERY_GEM_SOURCE'] || 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0'
gem 'sprockets-rails', '~> 3.5'
gem 'sprockets', '~> 4.2'
# Use SCSS for stylesheets
gem "dartsass-rails"
# Use Uglifier as compressor for JavaScript assets
gem 'terser'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11'
gem 'commontator', '~> 5.1.0'

############################
# Gems for Notebook Gallery
############################

gem 'acts_as_votable', '~> 0.13'
gem 'bootstrap-sass'
gem 'browser'
gem 'chartkick'
gem 'config'
gem 'devise', '~> 4.9'
gem 'doorkeeper', '~> 5.7'
gem 'git'
gem 'hightop'
gem 'jquery-datatables-rails'
gem 'jquery-slick-rails'
gem 'matrix'
gem 'metaid'
gem 'mysql2', '~> 0.5'
gem 'omniauth-facebook'
gem 'omniauth-github'
gem 'omniauth-gitlab'
gem 'omniauth-google-oauth2'
gem 'omniauth-azure-activedirectory-v2'
gem 'omniauth-rails_csrf_protection'
gem 'pry-rails'
gem 'puma', '~> 6.4'
gem 'rack-cors'
gem 'rufus-scheduler'
gem 'slim-rails'
gem 'will_paginate', '~> 4.0'
gem 'rails_same_site_cookie'

# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'execjs' # v2.8.0 requires replacing therubyracer with mini_racer
gem 'mini_racer', '~> 0.10'

# API clients
gem 'httmultiparty'
gem 'httparty'

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
gem 'ranker'
gem 'tf-idf'

# Instrumentation
gem 'russdeep'

# Notebook rendering
gem 'diffy'
gem 'redcarpet'
gem 'rouge'
gem 'bootsnap', '>= 1.1.0', require: false
#Better logging
gem 'lograge'

# Development only
group :development do
  gem 'dotenv'
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'slim_lint', require: false
  gem 'web-console', '>= 3.3.0'
  gem 'listen'
   # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'
end

group :test do
  gem 'rails-controller-testing'
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
