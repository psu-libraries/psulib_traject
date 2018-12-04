# frozen_string_literal: true

RSpec.describe 'Title spec:' do
  let(:indexer) do
    Traject::Indexer.new.tap do |i|
      i.load_config_file('./lib/traject/psulib_config.rb')
    end
  end
  let(:records) { MARC::Reader.new(fixtures_doc, external_encoding: 'UTF-8').to_a }
  let(:fixtures_doc) { File.new('./spec/fixtures/fixtures.mrc') }
  let(:results) { records.map { |rec| indexer.map_record(rec) }.to_a }

  describe 'Vernacular titles' do
    let(:result) { results.select { |r| r['id'] == ['2788022'] }.first }
    it 'has a vernacular title as the title statement' do
      expect(result).to include('title_display_ssm' => ['小說ワンダフルライフ / 是枝裕和'])
    end

    it 'has a latin title as the sub title' do
      expect(result).to include('title_latin_display_ssm' => ['Shōsetsu wandafuru raifu / Koreeda Hirokazu'])
    end
  end
end
