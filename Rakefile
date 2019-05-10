# frozen_string_literal: true

require 'rake/clean'
require 'time'

CLEAN.include('build')

Dir.glob(File.expand_path('task/*.rake', __dir__)) { |task| import task }

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
      title: #{title}
      date: #{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S %Z')}
      keywords:
        - TODO
      description: TODO
      ---

      A brief summary of the article.

      <!-- READ MORE -->

      The rest of the article
    TEMPLATE
  end
end

task default: :server
