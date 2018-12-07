# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Title spec:' do
  let(:indexer) do
    Traject::Indexer.new.tap do |i|
      i.load_config_file('./lib/traject/psulib_config.rb')
    end
  end

  let(:records) { MARC::Reader.new(fixtures_doc, external_encoding: 'UTF-8').to_a }
  let(:results) { records.map { |rec| indexer.map_record(rec) }.to_a }

  describe 'Record with a vernacular title' do
    let(:fixtures_doc) { File.new('./spec/fixtures/title_fixtures.mrc') }
    let(:field) { 'title_display_ssm' }
    let(:subfield) { 'title_latin_display_ssm' }
    subject(:result) { results.select { |r| r['id'] == ['2788022'] }.first }
    it 'has the vernacular title as the title statement' do
      expect(result[field]).to eq ['小說ワンダフルライフ / 是枝裕和']
      expect(result[field].length).to eq 1
    end

    it 'has a latin title as the sub-title' do
      expect(result[subfield]).to eq ['Shōsetsu wandafuru raifu / Koreeda Hirokazu']
      expect(result[subfield].length).to eq 1
    end

    it 'has empty vern title field' do
      expect(result).not_to include('title_vern')
    end
  end

  describe 'Record with no vernacular title' do
    let(:fixtures_doc) { File.new('./spec/fixtures/title_fixtures.mrc') }
    let(:field) { 'title_display_ssm' }
    let(:subfield) { 'title_latin_display_ssm' }
    subject(:result) { results.select { |r| r['id'] == ['2431513'] }.first }
    it 'has the latin title as the title statement' do
      expect(result[field]).to eq ['La ressemblance : suivi de la feintise, Jeff Edmunds / Jean Lahougue, Jeff Edmunds']
      expect(result[field].length).to eq 1
    end

    it 'has no latin title as the sub-title' do
      expect(result).not_to include(subfield)
    end

    it 'has empty vern title field' do
      expect(result).not_to include('title_vern')
    end
  end

  describe 'Related titles from 505t' do
    let(:fixtures_doc) { File.new('./spec/fixtures/title_related_505t_fixtures.mrc') }
    let(:field) { 'title_related_tsim' }
    subject(:result) { results.select { |r| r['id'] == ['12741571'] }.first }
    it 'returns with trailing -- chomped' do
      expect(result[field]).to(all(not_include(' --')))
    end
  end
end
