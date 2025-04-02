require 'benchmark'
require 'prometheus/client'

module Prometheus
  module Middleware
    class Collector
      attr_reader :app, :registry

      def initialize(app, options = {})
        @app = app
        @registry = options[:registry] || Client.registry
        @metrics_prefix = options[:metrics_prefix] || 'http_server'
      end

      def call(env) # :nodoc:
        trace(env) { @app.call(env) }
      end

      protected

      def trace(env)
        ACTIVE_REQUESTS.increment
        response = nil
        duration = Benchmark.realtime { response = yield }
        record(env, response.first.to_s, duration)
        ACTIVE_REQUESTS.decrement
        return response
      rescue => exception
        EXCEPTIONS_TOTAL.increment(labels: { exception: exception.class.name })
        ACTIVE_REQUESTS.decrement
        raise
      end

      def record(env, code, duration)
        path = generate_path(env)

        controller = env['action_dispatch.request.parameters']&.[]('controller') || 'unknown'
        action = env['action_dispatch.request.parameters']&.[]('action') || 'unknown'

        counter_labels = {
          controller: controller,
          action: action,
          method: env['REQUEST_METHOD'].downcase,
          code:   code,
          path:   path,
        }

        duration_labels = {
          controller: controller,
          action: action,
          method: env['REQUEST_METHOD'].downcase,
          path:   path,
        }

        HTTP_REQUESTS_TOTAL.increment(labels: counter_labels)
        REQUEST_DURATIONS.observe(duration, labels: duration_labels)
      rescue
        # TODO: log unexpected exception during request recording
        nil
      end

      def generate_path(env)
        full_path = [env['SCRIPT_NAME'], env['PATH_INFO']].join

        strip_ids_from_path(full_path)
      end

      def strip_ids_from_path(path)
        path
          .gsub(%r{/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(?=/|$)}, '/:uuid\\1')
          .gsub(%r{/\d+(?=/|$)}, '/:id\\1')
      end
    end
  end
end
