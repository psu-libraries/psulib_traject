require 'open-uri'
require 'json'

module UpdateLocations
  def self.call
    File.open("./lib/translation_maps/locations.properties", "w") do |file|
      file.truncate(0)
      open(url, headers) do |response|
        json = JSON.parse(response.read.to_s)
        json_sorted = json.sort_by{|i| i["fields"]["displayName"] }
        json_sorted_uniqd = json_sorted.uniq{|i| i["fields"]["displayName"] }
        json_sorted_uniqd.each do |line|
          file.write "#{line["fields"]["displayName"]} = #{line["fields"]["translatedDescription"]}\n"
        end
      end
    end
  end

  private

    def self.headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'sd-originating-app-id' => 'DHCTemplate',
        'x-sirs-clientID' => 'PSUCATALOG'
      }
    end

    def self.url
      'https://cat.libraries.psu.edu:28443/symwsbc/policy/location/simpleQuery?key=*&includeFields=displayName%2Cdescription%2CtranslatedDescription'
    end
end

UpdateLocations.call
