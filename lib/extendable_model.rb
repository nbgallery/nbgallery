# Extension support for models
module ExtendableModel
  # Load extensions when included by a model
  def self.included(klass)
    # This array should contain any attributes added to the model
    klass.meta_eval do
      attr_accessor :extension_attributes
    end
    klass.class_eval do
      self.extension_attributes = []
    end

    # Return if no extensions defined for this class
    key = klass.to_s.to_sym
    return if GalleryConfig.dig(:extensions, key).blank?

    # Load additional methods from the extensions
    GalleryConfig.extensions[key].each do |extension|
      Rails.logger.info("Adding #{extension} extension to #{key}")
      klass.class_eval do
        # Trigger Rails autoload
        include extension.constantize
      end
      if extension.constantize.const_defined?('ClassMethods') # rubocop: disable Style/Next
        klass.meta_eval do
          prepend "#{extension}::ClassMethods".constantize
        end
      end
    end
  end
end
