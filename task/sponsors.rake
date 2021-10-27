# frozen_string_literal: true

namespace :sponsors do
  desc 'Updates sponsor data'
  task :update do
    require_relative '../lib/sponsors'

    sponsors = Sponsors::Github.new.download

    sponsors.each do |sponsor|
      next if sponsor['image'].to_s.empty?

      sponsor['image'] = Sponsors::Image
        .new(sponsor['id'], sponsor['image'])
        .download
    end

    File.open('data/sponsors.yml', 'w') do |file|
      file.write(YAML.dump(sponsors))
    end
  end

  desc 'Prunes unused sponsor images'
  task :prune_logos do
    require_relative '../lib/sponsors'

    Sponsors::ImagePruner.new.prune
  end
end
