# frozen_string_literal: true
# rubocop: disable all

module Sponsors
  class Github
    HTTP = GraphQL::Client::HTTP.new('https://api.github.com/graphql') do
      def headers(*)
        { 'Authorization' => "bearer #{ENV.fetch('GITHUB_ACCESS_TOKEN')}" }
      end
    end

    SCHEMA = GraphQL::Client.load_schema(HTTP)
    CLIENT = GraphQL::Client.new(schema: SCHEMA, execute: HTTP)

    QUERY = CLIENT.parse(<<~GQL)
      query($after: String) {
        user(login: "yorickpeterse") {
          sponsorshipsAsMaintainer(includePrivate: true, first: 1, after: $after) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              createdAt
              privacyLevel

              tier {
                monthlyPriceInCents
              }
              sponsorEntity {
                ... on User {
                  databaseId
                  name
                  avatarUrl
                  websiteUrl
                  url
                }
                ... on Organization {
                  databaseId
                  name
                  avatarUrl
                  websiteUrl
                  url
                }
              }
            }
          }
        }
      }
    GQL

    def download
      api_data.map do |member|
        user = member.sponsor_entity
        amount = member.tier.monthly_price_in_cents
        created_at = Date.parse(member.created_at)
        months = months_since(created_at)
        total = amount * months
        tier =
          case amount
          when 500
            'backer'
          when 10_000
            'sponsor'
          else
            raise "No tier found for the amount $#{amount / 1_000}"
          end

        row = {
          'type' => 'private',
          'id' => nil,
          'name' => 'Anonymous',
          'image' => nil,
          'website' => nil,
          'total_donated' => total,
          'tier' => tier,
          'currency_symbol' => '$',
          'created_at' => created_at.iso8601
        }

        if member.privacy_level == 'PUBLIC'
          row['type'] = 'public'
          row['id'] = "gh-#{user.database_id}"
          row['name'] = user.name
          row['image'] = user.avatar_url
          row['website'] = user.website_url || user.url
        end

        row
      end
    end

    def api_data
      page = CLIENT.query(QUERY, variables: { after: nil })
      rows = []

      loop do
        page.data.user.sponsorships_as_maintainer.nodes.each do |row|
          rows << row
        end

        paging = page.data.user.sponsorships_as_maintainer.page_info

        if paging.has_next_page
          page = CLIENT.query(QUERY, variables: { after: paging.end_cursor })
        else
          break
        end
      end

      rows
    end

    def months_since(date)
      today = Date.today
      current = date
      amount = 0

      while current <= today
        amount += 1
        current >>= 1
      end

      amount
    end
  end
end
