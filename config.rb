# frozen_string_literal: true

require 'lib/inko_lexer'
require 'uglifier'
require 'time'

Haml::TempleEngine.disable_option_validator!

page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false
page '/*.ico', layout: false
page '/404.html', layout: :'404', directory_index: false
page '/', layout: :home

ignore '*.dot'

Time.zone = 'UTC'

set :website_title, 'Inko Programming Language'
set :website_author, 'The Inko Programming Language developers'
set :website_url, 'https://inko-lang.org'
set :feed_url, "#{config[:website_url]}/feed.xml"
set :markdown_engine, :kramdown

set :markdown,
    fenced_code_blocks: true,
    parse_block_html: true,
    auto_ids: true,
    auto_id_prefix: 'header-',
    tables: true,
    input: 'GFM',
    hard_wrap: false,
    toc_levels: 1..3

set :haml, format: :html5

activate :syntax, line_numbers: false

activate :blog do |blog|
  blog.prefix = 'news'
  blog.sources = '{title}.html'
  blog.permalink = '{title}/index.html'
  blog.layout = 'news'
  blog.summary_separator = '<!-- READ MORE -->'
end

activate :directory_indexes

configure :development do
  activate :livereload, host: 'localhost'
end

configure :build do
  activate :minify_css
  activate :minify_javascript, compressor: proc { Uglifier.new(harmony: true) }
  activate :asset_hash
end

# rubocop: disable Metrics/BlockLength
helpers do
  def markdown(text)
    Tilt['markdown'].new(config.markdown) { text }.render(self)
  end

  def sorted_sponsors(tier, &block)
    tier
      .sort { |a, b| b['total_donated'] <=> a['total_donated'] }
      .each(&block)
  end

  def sponsors_for_tier(tier)
    data.sponsors[tier] || []
  end

  def total_sponsors
    data.sponsors.reduce(0) do |total, (_, members)|
      total + members.length
    end
  end

  def sponsors?
    sponsors_for_tier('sponsor').any?
  end

  def backers?
    sponsors_for_tier('backer').any?
  end

  def sponsor_date(date)
    Date.strptime(date, '%Y-%m-%d').strftime('%B %Y')
  end

  def last_updated_at(path)
    Time.at(Integer(`git log -1 --format=%ct #{path} 2>&1`.strip))
  end
end
# rubocop: enable Metrics/BlockLength
