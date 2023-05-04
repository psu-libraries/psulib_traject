require 'open-uri'
require 'json'
require 'pry-byebug'

module UpdateLocations
  def self.call
    File.open("./lib/translation_maps/locations.properties", "w") do |file|
      file.truncate(0)
      json = JSON.parse(response.read.to_s)
      binding.pry
      open(url, headers) do |response|
        JSON.parse(response.read.to_s).each do |line|
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
