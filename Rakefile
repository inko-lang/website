# frozen_string_literal: true

require 'rake/clean'
require 'time'

CLEAN.include('build')

namespace :packages do
  desc 'Updates package data'
  task :update do
    require_relative 'lib/packages'

    pkgs = YAML.load_file('data/packages.yml').map do |meta|
      Package.new(meta['owner'], meta['name']).download
    end

    pkgs.sort_by! { |pkg| pkg['name'] }

    File.open('data/package_data.yml', 'w') do |file|
      file.write(YAML.dump(pkgs))
    end
  end
end

namespace :sponsors do
  desc 'Updates sponsor data'
  task :update do
    require_relative 'lib/sponsors'

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
    require_relative 'lib/sponsors'

    Sponsors::ImagePruner.new.prune
  end

  desc 'List the sponsors in Markdown'
  task :list do
    require 'yaml'

    entries = YAML
      .load_file('data/sponsors.yml')
      .sort_by { |r| r['name'].downcase }
      .map { |row| "- [#{row['name']}](#{row['website']})" }

    puts(entries)
  end
end

desc 'Generate a new news article'
task :news, :title do |_, args|
  abort 'You must specify a title' unless args.title

  title = args.title.strip
  filename = title
    .downcase
    .gsub(/[\s\.]+/, '-')
    .gsub(/[^\p{Word}\-]+/, '')

  File.open("source/news/#{filename}.html.md", 'w') do |handle|
    handle.puts <<~TEMPLATE.strip
      ---
      author: Your name here
      title: #{title.inspect}
      date: #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S %Z').inspect}
      ---


    TEMPLATE
  end
end

rule '.svg' => '.dot' do |task|
  sh "dot -T svg -o #{task.name} #{task.source}"
end

task images: %w[
  source/images/september-2019-progress-report/serial.svg
  source/images/september-2019-progress-report/parallel.svg
  source/images/september-2019-progress-report/modules.svg
  source/images/october-2019-progress-report/unreachable_young_object.svg
]

desc 'Builds the website'
task :build do
  sh 'bundle exec middleman build'
end

desc 'Builds the website and starts a server'
task :server do
  sh 'bundle exec middleman'
end

desc 'Updates the local build directory from S3'
task :download do
  sh "aws s3 sync --no-progress s3://#{ENV.fetch('BUCKET')} build"
end

desc 'Deploys the website'
task deploy: %i[download build] do
  bucket = ENV.fetch('BUCKET')
  dist = ENV.fetch('DISTRIBUTION_ID')
  flags = '--acl=public-read --cache-control max-age=86400'

  if ENV.key?('UPDATE_SPONSORS')
    sh "aws s3 cp build/sponsors/index.html " \
      "s3://#{bucket}/sponsors/index.html #{flags}" \
  else
    sh "aws s3 sync build s3://#{bucket} --delete #{flags} --no-progress"
  end

  sh "aws cloudfront create-invalidation --distribution-id #{dist} --paths '/*'"
end

task default: :server
