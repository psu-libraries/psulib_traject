# frozen_string_literal: true

RSpec.describe 'Bound with spec:' do
  let(:indexer) do
    Traject::Indexer.new.tap do |i|
      i.load_config_file('./lib/traject/psulib_config.rb')
    end
  end
  let(:fixtures_doc) { File.new('./spec/fixtures/bound_with_fixtures.mrc') }
  let(:records) { MARC::Reader.new(fixtures_doc, external_encoding: 'UTF-8').to_a }
  let(:results) { records.map { |rec| indexer.map_record(rec) }.to_a }

  describe 'Child items bound in' do
    subject(:result) { results.select { |r| r['id'] == ['1591'] }.first }
    it 'show the parent item it is bound into' do
      expect(result['bound_with_ss']).to include('Bound in: The high-caste Hindu woman / With introduction by Rachel L. Bodley, 355035 (parent record ckey)')
    end
  end
end
