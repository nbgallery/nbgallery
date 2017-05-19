Config.setup do |config|
  # Name of the constant exposing loaded settings
  config.const_name = 'GalleryConfig'

  # Merge arrays instead of overwrite
  config.overwrite_arrays = false

  # Ability to remove elements of the array set in earlier loaded settings file. For example value: '--'.
  config.knockout_prefix = '--'

  # Load environment variables from the `ENV` object and override any settings defined in files.
  config.use_env = true

  # Define ENV variable prefix deciding which variables to load into config.
  config.env_prefix = 'GALLERY'

  # What string to use as level separator for settings loaded from ENV variables. Default value of '.' works well
  # with Heroku, but you might want to change it for example for '__' to easy override settings from command line, where
  # using dots in variable names might not be allowed (eg. Bash).
  config.env_separator = '__'

  # Ability to process variables names:
  #   * nil  - no change
  #   * :downcase - convert to lower case
  config.env_converter = :downcase

  # Parse numeric values as integers instead of strings.
  config.env_parse_values = true
end
