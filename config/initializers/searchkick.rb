# initialize searchkick for opensearch
Searchkick.client = OpenSearch::Client.new(
  url: ENV.fetch("GALLERY__OPENSEARCH__URL", "http://opensearch:9200")
)
