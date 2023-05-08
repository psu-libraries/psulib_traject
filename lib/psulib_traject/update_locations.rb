# frozen_string_literal: true

require 'net/http'
require 'json'

module UpdateLocations
  class << self
    def call
      File.open(location_file_path, 'w') do |file|
        file.truncate(0)
        json = JSON.parse(response.to_s)
        json_sorted = json.sort_by { |i| i['fields']['displayName'] }
        json_sorted_uniqd = json_sorted.uniq { |i| i['fields']['displayName'] }
        json_sorted_uniqd.each do |line|
          file.write "#{line['fields']['displayName']} = #{line['fields']['translatedDescription']}\n"
        end
      end
    end

    private

      def response
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == 'https')
        request = Net::HTTP::Get.new(url, headers)
        http.request(request).body
      end

      def headers
        {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'sd-originating-app-id' => 'DHCTemplate',
          'x-sirs-clientID' => 'PSUCATALOG'
        }
      end

      def url
        URI.parse('https://cat.libraries.psu.edu:28443/symwsbc/policy/location/simpleQuery?key=*&includeFields=displayName,description,translatedDescription')
      end

      def location_file_path
        './lib/translation_maps/locations.properties'
      end
  end
end
