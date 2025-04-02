require 'prometheus/client'

prometheus = Prometheus::Client.registry

HTTP_REQUESTS_TOTAL = prometheus.counter(
  :http_requests_total,
  docstring: 'Total number of HTTP requests processed by NBGallery',
  labels: %i[controller action method code path]
)

ACTIVE_REQUESTS = prometheus.gauge(
  :active_requests,
  docstring: 'Number of currently active requests being processed by NBGallery',
  labels: %i[]
)

REQUEST_DURATIONS = prometheus.histogram(
  :http_request_duration_seconds,
  docstring: 'The HTTP response duration on NBGallery',
  labels: %i[controller action method path],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]
)

EXCEPTIONS_TOTAL = prometheus.counter(
  :http_exceptions_total,
  docstring: 'The total number of exceptions raised by NBGallery',
  labels: %i[exception]
)
