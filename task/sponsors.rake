# frozen_string_literal: true

namespace :sponsors do
  desc 'Updates sponsor data'
  task :update do
    require_relative '../lib/sponsor_data'

    SponsorData.new('inko-lang').update
  end

  desc 'Prunes unused sponsor images'
  task :prune_logos do
    require_relative '../lib/sponsor_data'

    SponsorData.new('inko-lang').prune_logos
  end
end
