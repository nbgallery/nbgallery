class Setting
  @settings_data = JSON.parse(File.read(GalleryConfig.toggle_settings_file), symbolize_names: true)
  
  def self.read_setting(setting_name)
    @settings_data[setting_name.to_sym]
  end

  def self.set_state(setting_name,new_state)
    @settings_data[setting_name.to_sym] = new_state
    
    File.write(GalleryConfig.toggle_settings_file, @settings_data.to_json)
    @settings_data = JSON.parse(File.read(GalleryConfig.toggle_settings_file), symbolize_names: true)
  end
end