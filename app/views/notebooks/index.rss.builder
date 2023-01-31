xml.rss(version: '2.0') do |rss| # rubocop: disable Metrics/BlockLength
  rss.channel do |channel| # rubocop: disable Metrics/BlockLength
    channel.title GalleryConfig.site.name
    channel.description "#{GalleryConfig.site.name} is a portal for publishing and sharing Jupyter notebooks."
    channel.link request.base_url
    channel.category 'jupyter'
    channel.category 'data science'
    channel.category 'python'
    channel.category 'ruby'
    channel.category 'R'
    channel.generator 'ruby'
    channel.image do |image|
      image.url "#{request.base_url}/images/nbgallery_logo.png"
      image.link "#{request.base_url}/?ref=rss"
      image.title GalleryConfig.site.name
      image.description GalleryConfig.site.name
      image.height 65
      image.width 150
    end
    channel.ttl 15 # minutes
    channel.lastBuildDate Time.current.httpdate

    channel.pubDate @notebooks.first.updated_at.httpdate rescue Time.current.httpdate

    @notebooks.each do |nb|
      channel.item do |item|
        item.title nb.title
        item.description nb.description
        item.link "#{request.base_url}#{notebook_path(nb, ref: :rss)}"
        item.category nb.lang
        item.author nb.updater.name
        item.guid "#{nb.uuid}-#{nb.updated_at.to_i}"
        item.pubDate nb.updated_at.httpdate
        item.creationDate nb.created_at.httpdate
        item.tags nb.tags.map(&:tag_text).join(' ')
      end
    end
  end
end
