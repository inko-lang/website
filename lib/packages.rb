# frozen_string_literal: true

require 'graphql/client'
require 'graphql/client/http'
require 'yaml'

class Package
  HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
    def headers(*)
      { 'Authorization' => "bearer #{ENV.fetch('PACKAGES_ACCESS_TOKEN')}" }
    end
  end

  SCHEMA = GraphQL::Client.load_schema(HTTP)
  CLIENT = GraphQL::Client.new(schema: SCHEMA, execute: HTTP)

  QUERY = CLIENT.parse(<<~GQL)
    query ($owner: String!, $name: String!, $after: String) {
      tags: repository(followRenames: true, owner: $owner, name: $name) {
        stargazerCount
        description
        url
        licenseInfo {
          name
        }
        refs(
          refPrefix: "refs/tags/"
          last: 100
          after: $after
          orderBy: { field: ALPHABETICAL, direction: DESC }
        ) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            name
            target {
              ... on Commit {
                committedDate
              }
            }
          }
        }
      }
    }
  GQL

  def initialize(owner, name)
    @owner = owner
    @name = name
  end

  def download
    get
  end

  def get
    page = CLIENT
      .query(QUERY, variables: { owner: @owner, name: @name, after: nil })
    repo = page.data.tags
    project = {
      'owner' => @owner,
      'name' => @name,
      'url' => repo.url,
      'description' => repo.description,
      'stars' => repo.stargazer_count,
      'license' => repo.license_info.name,
      'last_release' => nil,
      'versions' => [],
    }

    loop do
      page.data.tags.refs.nodes.each do |tag|
        name = if tag.name.start_with?('v')
          tag.name[1..-1]
        else
          tag.name
        end

        next unless name.match?(/^\d+\.\d+\.\d+$/)

        date = Time.parse(tag.target.committed_date).strftime('%Y-%m-%d %H:%M')
        project['versions'] << { 'name' => name, 'date' => date }
      end

      paging = page.data.tags.refs.page_info

      if paging.has_next_page
        page = CLIENT.query(
          QUERY,
          variables: { owner: @owner, name: @name, after: paging.end_cursor }
        )
      else
        break
      end
    end

    project
  end
end
