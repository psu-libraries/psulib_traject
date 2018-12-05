# frozen_string_literal: true

RSpec.describe 'Title spec:' do
  let(:indexer) do
    Traject::Indexer.new.tap do |i|
      i.load_config_file('./lib/traject/psulib_config.rb')
    end
  end
  let(:fixtures_doc) { File.new('./spec/fixtures/title_fixtures.mrc') }
  let(:records) { MARC::Reader.new(fixtures_doc, external_encoding: 'UTF-8').to_a }
  let(:results) { records.map { |rec| indexer.map_record(rec) }.to_a }

  describe 'Record with a vernacular title' do
    subject(:result) { results.select { |r| r['id'] == ['2788022'] }.first }
    it 'has the vernacular title as the title statement' do
      expect(result).to include('title_display_ssm': '小說ワンダフルライフ / 是枝裕和')
      expect(result['title_display_ssm'].length).to eq 1
    end

    it 'has a latin title as the sub-title' do
      expect(result).to include('title_latin_display_ssm': 'Shōsetsu wandafuru raifu / Koreeda Hirokazu')
      expect(result['title_latin_display_ssm'].length).to eq 1
    end
  end

  describe 'Record with no vernacular title' do
    subject(:result) { results.select { |r| r['id'] == ['2431513'] }.first }
    it 'has the latin title as the title statement' do
      expect(result).to include('title_display_ssm': 'La ressemblance : suivi de la feintise, Jeff Edmunds / Jean Lahougue, Jeff Edmunds')
      expect(result['title_display_ssm'].length).to eq 1
    end

    it 'has no latin title as the sub-title' do
      expect(result).not_to include('title_latin_display_ssm')
    end
  end
end
