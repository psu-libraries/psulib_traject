# frozen_string_literal: true
require_relative '../../../lib/psulib_traject/update_locations'

RSpec.describe UpdateLocations do
  describe '#call' do
    let(:location_file_path) { "spec/fixtures/locations.properties.test" }
    before do
      stub_request(:get, "https://cat.libraries.psu.edu:28443/symwsbc/policy/location/simpleQuery?includeFields=displayName,description,translatedDescription&key=*").
         with(
           headers: {
       	  'Accept'=>'application/json',
       	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	  'Content-Type'=>'application/json',
       	  'Host'=>'cat.libraries.psu.edu:28443',
       	  'Sd-Originating-App-Id'=>'DHCTemplate',
       	  'User-Agent'=>'Ruby',
       	  'X-Sirs-Clientid'=>'PSUCATALOG'
           }).
         to_return(status: 200, body: "[
          {
            \"resource\":\"/policy/location\",
            \"key\":\"FGHIJK\",
            \"fields\":{
              \"description\":\"The other place\",
              \"displayName\":\"FGHIJK\",
              \"translatedDescription\":\"The other place\"
            }
          },
          {
            \"resource\":\"/policy/location\",
            \"key\":\"ABCDE\",
            \"fields\":{
              \"description\":\"The place\",
              \"displayName\":\"ABCDE\",
              \"translatedDescription\":\"The place\"
            }
          },
          {
            \"resource\":\"/policy/location\",
            \"key\":\"ABCDE\",
            \"fields\":{
              \"description\":\"The place\",
              \"displayName\":\"ABCDE\",
              \"translatedDescription\":\"The place\"
            }
          },
          {
            \"resource\":\"/policy/location\",
            \"key\":\"VWXYZ\",
            \"fields\":{
              \"description\":\"The other other place\",
              \"displayName\":\"VWXYZ\",
              \"translatedDescription\":\"The other other place\"
            }
          }
        ]"
         )
      File.delete(location_file_path) if File.exists?(location_file_path)
      File.open(location_file_path, "w") {|f| f.write("Stuff to be deleted") }
      allow(described_class).to receive(:location_file_path).and_return(location_file_path)
    end

    after do
      File.delete(location_file_path) if File.exists?(location_file_path)
    end

    it 'pulls locations data and updates locations.properties with this data' do
      described_class.call
      expect(File.read(location_file_path)).to eq "ABCDE = The place\nFGHIJK = The other place\nVWXYZ = The other other place\n"
    end
  end
end