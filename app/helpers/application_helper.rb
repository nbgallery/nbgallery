# Application helpers
module ApplicationHelper
  def color_for(string)
    @colors ||= [
      '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf'
    ]
    @colors[string.sum % @colors.size]
  end
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def language_thumbnail(lang, lang_version=nil)
    if lang == 'python' && lang_version
      "python#{lang_version[0]}_thumbnail.png"
    else
      GalleryConfig.languages.dig(lang, :thumbnail) || GalleryConfig.languages.default.thumbnail
    end
  end

  def language_link(lang, lang_version=nil)
    if lang == 'python' && lang_version
      "/languages/python#{lang_version[0]}"
    else
      "/languages/#{lang}"
    end
  end
end
