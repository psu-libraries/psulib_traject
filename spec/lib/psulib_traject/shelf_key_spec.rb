# frozen_string_literal: true

RSpec.describe PsulibTraject::ShelfKey do
  subject { described_class.new(call_number) }

  context 'with a type LC number' do
    let(:call_number) { 'AB123 .C456 2000' }

    its(:forward) { is_expected.to eq('AB.0123.C456.2000') }
    its(:reverse) { is_expected.to eq('PO.ZYXW.NVUT.XZZZ~') }
  end

  context 'with a number that Lcsort cannot process' do
    let(:call_number) { 'Fiction G758thefu 2015' }

    its(:forward) { is_expected.to be_nil }
    its(:reverse) { is_expected.to be_nil }
  end
end
