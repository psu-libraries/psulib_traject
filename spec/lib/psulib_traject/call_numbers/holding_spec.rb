# frozen_string_literal: true

RSpec.describe PsulibTraject::CallNumbers::Holding do
  subject { described_class.call(record: record, context: context) }

  let(:field) { MARC::ControlField.new('001', '000000000') }
  let(:record) do
    MARC::Record.new.tap do |record|
      record.append(field)
    end
  end

   describe '#call' do
    context 'with an empty record' do
      let(:context) { instance_spy('Traject::Indexer::Context', output_hash: {}) }

      it { is_expected.to be_empty }
    end

    context 'with an online record' do
      let(:context) { instance_spy('Traject::Indexer::Context', output_hash: { access_facet: ["Online", "In the Library", "Free to Read"] }) }

      it { is_expected.to be_empty }
    end

    context 'with a local record' do
      let(:field) { MARC::DataField.new('949', '', '', ['a', 'xx(123456)']) }
      let(:context) { instance_spy('Traject::Indexer::Context', output_hash: {}) }

      it { is_expected.to be_empty }
    end
  end
end
