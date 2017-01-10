# encoding: utf-8
require 'forwardable'
require 'logger'

module MagicCloud
  # Debugging utilities class for cloud development itself
  class Debug
    class << self
      def instance
        @instance ||= new
      end

      extend Forwardable
      def_delegators :instance, :logger, :stats, :reset!
    end

    def initialize
      @logger = Logger.new(STDOUT).tap{|l| l.level = Logger::FATAL}
      @stats = Hash.new{|h, k| h[k] = 0}
    end

    attr_reader :logger, :stats

    def reset!
      @stats = Hash.new{|h, k| h[k] = 0}
    end
  end
end
