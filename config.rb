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
page '/manual.html', layout: :manual
page '/manual/*', layout: :manual
page '/', layout: :home

Time.zone = 'UTC'

set :website_title, 'Inko Programming Language'
set :website_author, 'Yorick Peterse'
set :website_url, 'https://inko-lang.org'
set :open_collective, 'https://opencollective.com/inko-lang'
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

activate :s3_sync do |s3|
  s3.bucket = 'inko-lang.org'
  s3.region = 'eu-west-1'
  s3.acl = 'public-read'
  s3.index_document = 'index.html'
  s3.error_document = '404.html'
end

default_caching_policy max_age: 24 * 60 * 60

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

  def link_to_manual_page(path)
    page = sitemap.find_resource_by_path("#{path}.html")

    link_to(page.data.title, page)
  end

  def sorted_sponsors(tier, &block)
    tier
      .sort { |a, b| b['total_donated'] <=> a['total_donated'] }
      .each(&block)
  end

  def sponsors_for_tier(tier)
    data.sponsors['tiers'][tier] || []
  end

  def total_sponsors
    data.sponsors['tiers'].reduce(0) do |total, (_, members)|
      total + members.length
    end
  end

  def sponsors?
    sponsors_for_tier('Sponsor').any?
  end

  def backers?
    sponsors_for_tier('Backer').any?
  end

  def annual_budget
    data.sponsors['budget'].floor
  end

  def format_date(date)
    Date.strptime(date, '%Y-%m-%d %H:%M').strftime('%B %e, %Y')
  end
end
# rubocop: enable Metrics/BlockLength
