module Seeder
  class << self
    def load_seed
      default_seed = File.join(Rails.root.to_s, 'db', 'seeds.rb')
      if File.exist?(default_seed)
        Rails.logger.info("Loading default seeds from #{default_seed}")
        load default_seed
      end

      GalleryLib.extensions.each do |name, info|
        seeds = File.join(info[:dir], 'seeds.rb')
        if File.exist?(seeds)
          Rails.logger.info("Loading extension seeds from #{seeds}")
          load seeds
        end
      end
    end
  end
end
