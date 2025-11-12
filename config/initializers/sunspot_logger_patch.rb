# config/initializers/sunspot_logger_patch.rb
module Sunspot
  module Rails
    class LogSubscriber < ActiveSupport::LogSubscriber
      unless const_defined?(:BOLD)
        BOLD = "\e[1m"
      end
      unless const_defined?(:CLEAR)
        CLEAR = "\e[0m"
      end
      def request(event)
        name = "Solr request (#{event.payload[:path]})"
        duration = event.duration.round(1)
        debug "  #{color(name, [:bold, :yellow])} (#{duration}ms)"
      end
    end
  end
end
