# frozen_string_literal: true

RSpec.describe PsulibTraject::Holdings do
  subject(:holdings) { described_class.call(record: record, context: context) }

  let(:fields) { [MARC::ControlField.new('001', '000000000')] }
  let(:record) do
    MARC::Record.new.tap do |record|
      fields.map do |field|
        record.append(field)
      end
    end
  end
  let(:context) { instance_spy('Traject::Indexer::Context', output_hash: {}) }

  let(:mocked_lc_holding) { instance_spy(PsulibTraject::CallNumbers::LC, lopped: 'LC Call Number') }
  let(:mocked_lcper_holding) { instance_spy(PsulibTraject::CallNumbers::LC, lopped: 'LCPER Call Number') }
  let(:mocked_dewey_holding) { instance_spy(PsulibTraject::CallNumbers::Dewey, lopped: 'Dewey Call Number') }
  let(:mocked_other_holding) { instance_spy(PsulibTraject::CallNumbers::Other, lopped: 'ASIS Call Number') }

  before do
    allow(PsulibTraject::CallNumbers::LC).to receive(:new).with('LC Call Number').and_return(mocked_lc_holding)
    allow(PsulibTraject::CallNumbers::LC).to receive(:new).with('LCPER Call Number').and_return(mocked_lcper_holding)
    allow(PsulibTraject::CallNumbers::Dewey).to receive(:new).with('Dewey Call Number').and_return(mocked_dewey_holding)
    allow(PsulibTraject::CallNumbers::Other).to receive(:new).with('ASIS Call Number').and_return(mocked_other_holding)
  end

  describe '#call' do
    context 'with an empty record' do
      it { is_expected.to be_empty }
    end

    context 'with an online record' do
      let(:context) { instance_spy('Traject::Indexer::Context', output_hash: { access_facet: ["Online", "In the Library", "Free to Read"] }) }

      it { is_expected.to be_empty }
    end

    context 'with an on order record' do
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'Call Number'], ['l', 'ON-ORDER'])] }

      it { is_expected.to be_empty }
    end

    context 'with a local record' do
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'xx(Call Number)'])] }

      it { is_expected.to be_empty }
    end

    context 'with a periodical record' do
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'Periodical'])] }

      it { is_expected.to be_empty }
    end

    context 'with a record that has two holdings with same call number' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'LC Call Number'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'LC Call Number'], ['w', 'LC'], ['l', 'Location'])
        ]
      end

      it { is_expected.to contain_exactly 'LC Call Number' }
    end

    context 'with a record that has holdings with different classifications' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'LC Call Number'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'LCPER Call Number'], ['w', 'LCPER'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'Dewey Call Number'], ['w', 'DEWEY'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'ASIS Call Number'], ['w', 'ASIS'], ['l', 'Location'])
        ]
      end

      it { is_expected.to contain_exactly  'ASIS Call Number', 'Dewey Call Number', 'LC Call Number', 'LCPER Call Number' }
    end

    context 'with a record that has holdings with identical base call numbers' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'LC Call Number v.1'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'LC Call Number v.2'], ['w', 'LC'], ['l', 'Location'])
        ]
      end

      let(:mocked_lc_holding_1) { instance_spy(PsulibTraject::CallNumbers::LC, lopped: 'LC Call Number v.1') }
      let(:mocked_lc_holding_2) { instance_spy(PsulibTraject::CallNumbers::LC, lopped: 'LC Call Number v.2') }

      before do
        allow(PsulibTraject::CallNumbers::LC).to receive(:new).with('LC Call Number v.1').and_return(mocked_lc_holding_1)
        allow(PsulibTraject::CallNumbers::LC).to receive(:new).with('LC Call Number v.2').and_return(mocked_lc_holding_2)
        allow(mocked_lc_holding_1).to receive(:lopped).and_return('LC Call Number')
        allow(mocked_lc_holding_2).to receive(:lopped).and_return('LC Call Number')
      end

      it { is_expected.to contain_exactly'LC Call Number' }
    end
  end
end
