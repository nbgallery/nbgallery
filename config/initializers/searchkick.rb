# initialize searchkick for opensearch
opensearch_url = GalleryConfig.opensearch.hosturl || "http://opensearch:9200"

Searchkick.client = OpenSearch::Client.new(
  url: opensearch_url,
  retry_on_failure: true
)
