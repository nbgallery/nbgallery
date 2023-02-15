# Application helpers
module ApplicationHelper
  def color_for(string)
    @colors ||= [
      #'#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd', '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf' //better but not 4.5:1 contrast ratio (accessibility)
      '#1f77b4', '#be5900', '#258825', '#d62728', '#8f60ba', '#8c564b', '#d32ba0', '#757575', '#797a16', '#10838e'
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

  def chart_colors
    # default colors from chartkick js source
    [
      '#3366CC', # blue
      '#DC3912', # red
      '#FF9900', # orange
      '#109618', # green
      '#990099', # purple
      '#3B3EAC', # indigo
      '#0099C6', # light blue
      '#DD4477', # pink
      '#66AA00', # green
      '#B82E2E', # dark red
      '#316395', # dark blue
      '#994499', # dark purple
      '#22AA99', # teal
      '#AAAA11', # olive
      '#6633CC', # purple
      '#E67300', # orange
      '#8B0707', # dark red
      '#329262', # grey green
      '#5574A6', # grey blue
      '#3B3EAC'  # dark purple
    ]
  end

  def chart_colors_blue_red
    chart_colors[0..1]
  end

  def chart_colors_no_red
    chart_colors - ['#DC3912', '#B82E2E', '#8B0707']
  end

  def code_cell_path(cell)
    notebook_code_cell_path(cell.notebook, cell)
  end

  def revision_path(rev)
    notebook_revision_path(rev.notebook, rev)
  end

  def link_to_revision(rev)
    Rails.logger.warn('The rails helper "link_to_revision" is deprecated for this application. To ensure your revision links are able to show the user-friendly label, use the _link.slim partial instead.')
    link_to(rev.commit_id.first(8), revision_path(rev))
  end

  def link_to_notebook(nb, options={})
    link_to(nb.title, notebook_path(nb, options))
  end

  def link_to_user(user)
    if user == nil || user.id == nil
      "Unknown"
    elsif user.org != nil && user.org.length > 0
      link_to(user.name, user, class: "tooltips", title: "#{user.name} (#{user.org})")
    else
      link_to(user.name, user)
    end
  end

  def link_to_group(group)
    link_to(group.name, group)
  end
end
