# frozen_string_literal: true

module Sponsors
  class OpenCollective
    def download
      api_data.each_with_object([]) do |member, members|
        next unless member['tier']
        next unless member['isActive']

        members << {
          'type' => 'public',
          'id' => "oc-#{member['MemberId']}",
          'name' => member['name'],
          'image' => member['image'],
          'website' => member['website'] || member['profile'],
          'total_donated' => member['totalAmountDonated'] * 100,
          'tier' => member['tier'].downcase,
          'currency_symbol' => '€',
          'created_at' => Date.parse(member['createdAt']).iso8601
        }
      end
    end

    def api_data
      resp = HTTP.get('https://opencollective.com/inko-lang/members.json')

      if resp.status != 200
        raise "Failed to obtain the data from Open Collective: #{resp.reason}"
      end

      JSON.parse(resp.body.to_s)
    end
  end
end
