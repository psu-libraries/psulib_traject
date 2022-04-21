# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::OclcExtract do
  let(:oclc_extract) { described_class.new(record, accumulator) }
  let(:leader) { '1234567890' }

  describe '#extract_deprecated_oclcs' do
    let(:fields) do
      [
        { '035' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'z' => '(OCoLC)12345678' }
          ]
        } },
        { '019' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'a' => '87654321' }
          ]
        } },
        { '019' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'a' => '8765432121351235123515' }
          ]
        } },
        { '019' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'a' => 'MARS' }
          ]
        } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:accumulator) { [] }

    it 'extracts deprecated oclcs' do
      oclc_extract.extract_deprecated_oclcs
      expect(accumulator).to eq ['12345678', '87654321']
    end
  end

  describe '#extract_primary_oclcs' do
    let(:fields) do
      [
        { '035' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'a' => '(OCoLC)56789123' }
          ]
        } },
        { '035' => {
          'ind1' => '',
          'ind2' => '',
          'subfields' => [
            { 'z' => '(OCoLC)12345678' }
          ]
        } }
      ]
    end
    let(:record) { MARC::Record.new_from_hash('fields' => fields, 'leader' => leader) }
    let(:accumulator) { [] }

    it 'extracts primary oclc' do
      oclc_extract.extract_primary_oclc
      expect(accumulator).to eq ['56789123']
    end
  end
end
