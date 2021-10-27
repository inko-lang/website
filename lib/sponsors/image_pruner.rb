# frozen_string_literal: true

module Sponsors
  class ImagePruner
    def prune
      path = File.expand_path('../../data/sponsors.yml', __dir__)
      yaml = YAML.safe_load(File.read(path))
      keep = Set.new

      yaml.each do |sponsor|
        next unless sponsor['image']

        keep << File.basename(sponsor['image'])
      end

      Dir[Sponsors::Image::DIRECTORY.join('*.*')].each do |file|
        name = File.basename(file)

        File.unlink(file) unless keep.include?(name)
      end
    end
  end
end
