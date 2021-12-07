# frozen_string_literal: true

RSpec.describe PsulibTraject::PeriodicalHoldings do
  subject(:holdings) { described_class.new }

  describe '#library' do
    let(:library_code) { Faker::Lorem.word }

    before { holdings.heading = MARC::DataField.new('252', '0', '0', ['b', library_code]) }

    its(:library) { is_expected.to eq(library_code) }
  end

  describe '#location' do
    let(:location_code) { Faker::Lorem.word }

    before { holdings.heading = MARC::DataField.new('252', '0', '0', ['c', location_code]) }

    its(:location) { is_expected.to eq(location_code) }
  end

  describe '#call_number' do
    context 'with only subfield h' do
      before { holdings.heading = MARC::DataField.new('252', '0', '0', ['h', 'QA1 .C73']) }

      its(:call_number) { is_expected.to eq('QA1 .C73') }
    end

    context 'with subfield h and i' do
      before { holdings.heading = MARC::DataField.new('252', '0', '0', ['h', 'QA1 .C73'], ['i', '1999']) }

      its(:call_number) { is_expected.to eq('QA1 .C73 1999') }
    end
  end

  describe '#summary' do
    before { holdings.add_summary(MARC::DataField.new('266', '0', '0', ['a', 'v.12(1956/57)-v.40:1-7/8(1984)'])) }

    its(:summary) { is_expected.to contain_exactly('v.12(1956/57)-v.40:1-7/8(1984)') }
  end

  describe '#supplement' do
    before { holdings.add_supplement(MARC::DataField.new('267', '0', '0', ['a', 'supplement statement'])) }

    its(:supplement) { is_expected.to contain_exactly('supplement statement') }
  end

  describe '#index' do
    before { holdings.add_index(MARC::DataField.new('268', '0', '0', ['a', 'index statement'])) }

    its(:index) { is_expected.to contain_exactly('index statement') }
  end

  describe '#to_hash' do
    # @note Since DataField is just a kind of hash, we're using that for simplicity
    before do
      holdings.heading = { 'b' => 'Library', 'c' => 'Location', 'h' => 'Call Number' }
      holdings.add_summary({ 'a' => 'The First Summary' })
      holdings.add_summary({ 'a' => 'The Second Summary' })
      holdings.add_supplement({ 'a' => 'The First Supplement' })
      holdings.add_supplement({ 'a' => 'The Second Supplement' })
      holdings.add_index({ 'a' => 'The First Index' })
      holdings.add_index({ 'a' => 'The Second Index' })
    end

    let(:sample) do
      {
        library: 'Library',
        location: 'Location',
        call_number: 'Call Number',
        summary: ['The First Summary', 'The Second Summary'],
        supplement: ['The First Supplement', 'The Second Supplement'],
        index: ['The First Index', 'The Second Index']
      }
    end

    its(:to_hash) { is_expected.to eq(sample) }
  end
end
