xml.rss(version: '2.0') do |rss|
  rss.channel do |channel|
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

    channel.pubDate @feed.first.updated_at.httpdate rescue Time.current.httpdate

    @feed.each do |event|
      nb = event.notebook
      action = event.action.sub('notebook', '').strip
      channel.item do |item|
        item.title "#{nb.title} [#{action}]"
        item.description nb.description
        item.link "#{request.base_url}#{nb.friendly_url}?ref=rss"
        item.category nb.lang
        item.author "#{event.user.email} (#{event.user.name})"
        item.guid "#{nb.uuid}-#{event.updated_at.to_i}"
        item.pubDate event.updated_at.httpdate
      end
    end
  end
end
