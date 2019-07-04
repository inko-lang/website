# frozen_string_literal: true

# rubocop: disable Metrics/BlockLength
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

  desc 'Commit sponsor changes from CI'
  task commit: %i[update prune_logos] do
    sh 'git add --all source/images/sponsors'

    begin
      sh 'git commit -m "Update sponsors data from Open Collective" ' \
        '--author "GitLab CI <gitlab@inko-lang.org>"'
    rescue RuntimeError
      puts 'Nothing to commit'
      next
    end

    retried = 0

    begin
      sh 'git push origin master'
    rescue RuntimeError
      raise 'Failed to push after three retries' if retried == 3

      retried += 1
      retry
    end
  end
end
# rubocop: enable Metrics/BlockLength
