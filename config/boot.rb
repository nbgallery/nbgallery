require 'logger'
Fixnum = Integer unless defined?(Fixnum)
Bignum = Integer unless defined?(Bignum)
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
