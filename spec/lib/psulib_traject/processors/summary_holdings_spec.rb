# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::SummaryHoldings do
  describe '::call' do
    subject(:holdings) { described_class.call(record: record) }

    context 'when there are no summary holdings' do
      let(:record) { MarcBot.build(:record) }

      it { is_expected.to be_empty }
    end

    context 'when there is a summary holdings unit' do
      let(:record) { MarcBot.build(:single_summary_holdings) }

      it 'returns one Unit object' do
        expect(holdings).to be_a(Hash)
        expect(holdings['UP-SPECCOL']['HC-SERIALS']).to contain_exactly(
          call_number: 'HD6515.P4 I5 F',
          index: ['Index'],
          summary: ['v.12(1956/57)-v.40:1-7/8(1984)'],
          supplement: ['Supplemental']
        )
      end
    end

    context 'when multiple summary holdings are present' do
      let(:record) { MarcBot.build(:multiple_summary_holdings) }

      it 'returns two Unit objects' do
        expect(holdings).to be_a(Hash)
        expect(holdings['UP-ANNEX']['CATO-2']).to contain_exactly(
          call_number: 'HX1 .M3',
          index: [],
          summary: [],
          supplement: []
        )
        expect(holdings['UP-ANNEX']['CATO-3']).to contain_exactly(
          {
            call_number: 'AC1 .X98',
            index: [],
            summary: [],
            supplement: []
          },
          {
            call_number: 'AC1 .X99',
            index: [],
            summary: ['v.1(2000)- to Date.'],
            supplement: []
          }
        )
        expect(holdings['UP-SPECCOL']['HC-SERIALS']).to contain_exactly(
          call_number: 'HD6515.P4 I5 F',
          index: ['Index'],
          summary: ['v.12(1956/57)-v.40:1-7/8(1984)'],
          supplement: ['Supplemental']
        )
      end
    end
  end
end
