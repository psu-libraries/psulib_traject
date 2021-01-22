# frozen_string_literal: true

require './lib/psulib_traject/solr_manager'
require 'config'

RSpec.describe PsulibTraject::SolrManager do
  subject(:solr_manager) { described_class.new }

  describe '#last_incremented_collection' do
    before do
      stub_request(:get, 'http://localhost:8983/solr/admin/collections?action=LIST')
        .to_return(status: 200, body: '{"responseHeader":{"status":0,"QTime":0},"collections":["psul_catalog_v1","psul_catalog_v2"]}', headers: {})
    end

    it 'emits the last incremented collection' do
      expect(solr_manager.last_incremented_collection.to_s).to eq 'psul_catalog_v2'
    end
  end
end
