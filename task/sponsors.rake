# frozen_string_literal: true

namespace :sponsors do
  desc 'Updates sponsor data'
  task :update do
    require_relative '../lib/sponsors'
    require_relative '../lib/sponsors/open_collective'
    require_relative '../lib/sponsors/github'

    sponsors =
      Sponsors::OpenCollective.new.download + Sponsors::Github.new.download

    sponsors.each do |sponsor|
      next if sponsor['image'].to_s.empty?

      sponsor['image'] = Sponsors::Image
        .new(sponsor['id'], sponsor['image'])
        .download
    end

    File.open('data/sponsors.yml', 'w') do |file|
      file.write(YAML.dump(sponsors.group_by { |sponsor| sponsor['tier'] }))
    end
  end

  desc 'Prunes unused sponsor images'
  task :prune_logos do
    require_relative '../lib/sponsors'

    Sponsors::ImagePruner.new.prune
  end
end
