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
    before do
      holdings.add_summary(
        MARC::DataField.new(
          '266', '0', '0',
          ['a', 'v.12(1956/57)-v.40:1-7/8(1984)'],
          ['b', 'extra summary statement b'],
          ['c', 'extra summary statement c'],
          ['z', 'extra summary statement z']
        )
      )
    end

    its(:summary) { is_expected.to contain_exactly(
      'v.12(1956/57)-v.40:1-7/8(1984)',
      'extra summary statement b',
      'extra summary statement c',
      'extra summary statement z'
    )}
  end

  describe '#supplement' do
    before do
      holdings.add_supplement(
        MARC::DataField.new(
          '267', '0', '0',
          ['a', 'supplement statement'],
          ['b', 'extra supplement statement b'],
          ['c', 'extra supplement statement c'],
          ['z', 'extra supplement statement z']
        )
      )
    end

    its(:supplement) { is_expected.to contain_exactly(
      'supplement statement',
      'extra supplement statement b',
      'extra supplement statement c',
      'extra supplement statement z'
    )}
  end

  describe '#index' do
    before do
      holdings.add_index(
        MARC::DataField.new(
          '268', '0', '0',
          ['a', 'index statement'],
          ['b', 'extra index statement b'],
          ['c', 'extra index statement c'],
          ['z', 'extra index statement z']
        )
      )
    end

    its(:index) { is_expected.to contain_exactly(
      'index statement',
      'extra index statement b',
      'extra index statement c',
      'extra index statement z'
    )}
  end

  describe '#to_hash' do
    let(:record) { MarcBot.build(:sample_summary_holdings) }
    let(:sample) do
      {
        library: 'Library',
        location: 'Location',
        call_number: 'Call Number',
        summary: ['the first summary', 'extra summary 1', 'the second summary', 'extra summary 2'],
        supplement: ['the first supplement', 'extra supplement 1', 'the second supplement', 'extra supplement 2'],
        index: ['the first index', 'extra index 1', 'the second index', 'extra index 2']
      }
    end

    before do
      holdings.heading = record['852']
      holdings.add_summary(record.fields('866')[0])
      holdings.add_summary(record.fields('866')[1])
      holdings.add_supplement(record.fields('867')[0])
      holdings.add_supplement(record.fields('867')[1])
      holdings.add_index(record.fields('868')[0])
      holdings.add_index(record.fields('868')[1])
    end

    its(:to_hash) { is_expected.to eq(sample) }
  end
end
