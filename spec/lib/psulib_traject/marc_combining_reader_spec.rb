# frozen_string_literal: true

RSpec.describe PsulibTraject::MarcCombiningReader do
  subject(:reader) { described_class.new(File.open(File.join(fixture_path, 'split_items_test.mrc').to_s, 'r'), 'marc_source.type' => 'binary') }

  let(:fixture_path) { './spec/fixtures' }
  let(:results) { reader.each.to_a }

  describe '#each' do
    it 'merges MARC records when their 001 fields match' do
      expect(results.length).to eq 5

      expect(results.map { |x| x['001'].value }).to eq %w[anotSplit1 anotSplit2 asplit1 asplit2 asplit3]

      asplit1 = results.find { |r| r['001'].value == 'asplit1' }
      expect(asplit1.fields('008').length).to eq 1
      expect(asplit1.fields('245').length).to eq 1
      expect(asplit1.fields('949').length).to eq 5
      expect(asplit1.fields('949').map { |x| x['a'] }).to eq ['A1 .B2 V.1', 'A1 .B2 V.2', 'A1 .B2 V.3', 'A1 .B2 V.4', 'A1 .B2 V.5']

      asplit3 = results.find { |r| r['001'].value == 'asplit3' }
      expect(asplit3.fields('591').length).to eq 1
      expect(asplit3.fields('591').map { |x| x['a'] }).to eq ['Parent Title']
      expect(asplit3.fields('591').map { |x| x['c'] }).to eq ['Parent Catkey']
    end
  end
end
