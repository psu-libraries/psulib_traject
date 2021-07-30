# frozen_string_literal: true

RSpec.describe PsulibTraject::SolrManager do
  subject(:solr_manager) { described_class.new }

  let(:port) { ConfigSettings.solr.port || '8983' }

  describe '#last_incremented_collection' do
    before do
      stub_request(:get, "http://localhost:#{port}/solr/admin/collections?action=LIST")
        .to_return(
          status: 200,
          body: '{"responseHeader":{"status":0,"QTime":0},"collections":["psul_catalog_v1","psul_catalog_v2"]}',
          headers: {}
        )
    end

    it 'emits the last incremented collection' do
      expect(solr_manager.last_incremented_collection.to_s).to eq 'psul_catalog_v2'
    end
  end
end
