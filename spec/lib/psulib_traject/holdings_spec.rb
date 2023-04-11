# frozen_string_literal: true

RSpec.describe PsulibTraject::Holdings do
  subject(:holdings) do
    described_class.call(record: record, context: context).map(&:value)
  end

  let(:fields) { [MARC::ControlField.new('001', '000000000')] }
  let(:record) do
    MARC::Record.new.tap do |record|
      fields.map do |field|
        record.append(field)
      end
    end
  end
  let(:context) { instance_spy('Traject::Indexer::Context', output_hash: {}) }

  let(:mocked_lc_holding) { instance_spy(PsulibTraject::Processors::CallNumber::LC, reduce: 'AB123 .C456 2000 LC Call Number') }
  let(:mocked_lcper_holding) { instance_spy(PsulibTraject::Processors::CallNumber::LC, reduce: 'AB123 .C456 2000 LCPER Call Number') }
  let(:mocked_dewey_holding) { instance_spy(PsulibTraject::Processors::CallNumber::Dewey, reduce: '123.1A23a Dewey Call Number') }
  let(:mocked_other_holding) { instance_spy(PsulibTraject::Processors::CallNumber::Other, reduce: 'ASIS Call Number') }

  before do
    allow(PsulibTraject::Processors::CallNumber::LC).to receive(:new).with('AB123 .C456 2000 LC Call Number', serial: false)
      .and_return(mocked_lc_holding)
    allow(PsulibTraject::Processors::CallNumber::LC).to receive(:new).with('AB123 .C456 2000 LCPER Call Number', serial: false)
      .and_return(mocked_lcper_holding)
    allow(PsulibTraject::Processors::CallNumber::Dewey).to receive(:new).with('123.1A23a Dewey Call Number', serial: false)
      .and_return(mocked_dewey_holding)
    allow(PsulibTraject::Processors::CallNumber::Other).to receive(:new).with('ASIS Call Number').and_return(mocked_other_holding)
  end

  describe '#call' do
    let(:context) { instance_spy('Traject::Indexer::Context',
                                 output_hash: { 'access_facet' => ['Online', 'In the Library', 'Free to Read'] }) }

    context 'with an empty record' do
      it { is_expected.to be_empty }
    end

    context 'with an online record that is also "In the Library"' do
      let(:fields) do
        [MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location'])]
      end

      it { is_expected.to contain_exactly 'AB123 .C456 2000 LC Call Number' }
    end

    context 'with an online record that is not "In the Library"' do
      let(:fields) do
        [MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location'])]
      end
      let(:context) { instance_spy('Traject::Indexer::Context',
                                   output_hash: { 'access_facet' => ['Online', 'Free to Read'] }) }

      it { is_expected.to be_empty }
    end

    context 'with a record that is not online or "In the Library"' do
      let(:fields) do
        [MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location'])]
      end
      let(:context) { instance_spy('Traject::Indexer::Context',
                                   output_hash: { 'access_facet' => ['Free to Read'] }) }

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
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'Periodical Fiche v.17-v.40'])] }

      it { is_expected.to be_empty }
    end

    context 'with a record that has non browsable lc call number' do
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'Some Call Number'], ['w', 'LC'])] }

      it { is_expected.to be_empty }
    end

    context 'with a record that has non browsable dewey call number' do
      let(:fields) { [MARC::DataField.new('949', '', '', ['a', 'Microfilm E243 June 1-15 2021'], ['w', 'DEWEY'])] }

      it { is_expected.to be_empty }
    end

    context 'with a record that has two holdings with same call number' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location'])
        ]
      end

      it { is_expected.to contain_exactly 'AB123 .C456 2000 LC Call Number' }
    end

    context 'with a record that has holdings with different classifications' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LCPER Call Number'], ['w', 'LCPER'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', '123.1A23a Dewey Call Number'], ['w', 'DEWEY'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'ASIS Call Number'], ['w', 'ASIS'], ['l', 'Location'])
        ]
      end

      it { is_expected.to contain_exactly '123.1A23a Dewey Call Number', 'AB123 .C456 2000 LC Call Number', 'AB123 .C456 2000 LCPER Call Number' }
    end

    context 'with a record that has holdings with identical base call numbers' do
      let(:fields) do
        [
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number v.1'], ['w', 'LC'], ['l', 'Location']),
          MARC::DataField.new('949', '', '', ['a', 'AB123 .C456 2000 LC Call Number v.2'], ['w', 'LC'], ['l', 'Location'])
        ]
      end

      let(:mocked_lc_holding_1) { instance_spy(PsulibTraject::Processors::CallNumber::LC, reduce: 'AB123 .C456 2000 LC Call Number v.1') }
      let(:mocked_lc_holding_2) { instance_spy(PsulibTraject::Processors::CallNumber::LC, reduce: 'AB123 .C456 2000 LC Call Number v.2') }

      before do
        allow(PsulibTraject::Processors::CallNumber::LC).to receive(:new).with('AB123 .C456 2000 LC Call Number v.1', serial: false)
          .and_return(mocked_lc_holding_1)
        allow(PsulibTraject::Processors::CallNumber::LC).to receive(:new).with('AB123 .C456 2000 LC Call Number v.2', serial: false)
          .and_return(mocked_lc_holding_2)
        allow(mocked_lc_holding_1).to receive(:reduce).and_return('AB123 .C456 2000 LC Call Number')
        allow(mocked_lc_holding_2).to receive(:reduce).and_return('AB123 .C456 2000 LC Call Number')
      end

      it { is_expected.to contain_exactly 'AB123 .C456 2000 LC Call Number' }
    end
  end
end
