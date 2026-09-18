class Setting
  def self.file_path
    GalleryConfig.toggle_settings_file
  end

  def self.read_setting(setting_name)
    current_last_modified = File.exist?(file_path) ? File.mtime(file_path) : Time.at(0)

    if @last_modified.nil? || current_last_modified > @last_modified
      data_load = load_from_disk
      if data_load.present?
        @cached_settings = data_load
        @last_modified = current_last_modified
      else
        Rails.logger.error("ERROR: Failed to load current file data. Please check file path or try again.")
      end
    end
    @cached_settings[setting_name.to_sym]
  end

  def self.set_state(setting_name, new_state)
    @cached_settings ||= {}
    @cached_settings[setting_name.to_sym] = new_state
    File.write(file_path, JSON.generate(@cached_settings))
  end

  def self.load_from_disk
    File.exist?(file_path) ? JSON.parse(File.read(file_path), symbolize_names: true) : {}
  rescue JSON::ParserError
    Rails.logger.error.("Error: Could not parse settings file.")
    {}
  end
end
