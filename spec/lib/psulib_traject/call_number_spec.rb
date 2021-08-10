# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::CallNumber do
  context "when value is 'Periodical'" do
    subject { described_class.new(value: 'Periodical') }

    it { is_expected.to be_periodical }
    it { is_expected.not_to be_newspaper }
    it { is_expected.not_to be_local }
    it { is_expected.not_to be_on_order }
    it { is_expected.to be_exclude }
  end

  context "when value is 'Newspaper'" do
    subject { described_class.new(value: 'Newspaper') }

    it { is_expected.not_to be_periodical }
    it { is_expected.to be_newspaper }
    it { is_expected.not_to be_local }
    it { is_expected.not_to be_on_order }
    it { is_expected.to be_exclude }
  end

  context "when value starts with 'xx('" do
    subject { described_class.new(value: 'xx(asdf1234)') }

    it { is_expected.not_to be_periodical }
    it { is_expected.not_to be_newspaper }
    it { is_expected.to be_local }
    it { is_expected.not_to be_on_order }
    it { is_expected.to be_exclude }
  end

  context "when location is 'ON-ORDER'" do
    subject { described_class.new(location: 'ON-ORDER') }

    it { is_expected.not_to be_periodical }
    it { is_expected.not_to be_newspaper }
    it { is_expected.not_to be_local }
    it { is_expected.to be_on_order }
    it { is_expected.to be_exclude }
  end

  describe '#serial?' do
    context 'when not a serial record' do
      subject { described_class.new(item_type: 'NOT_SERIAL') }

      it { is_expected.not_to be_serial }
    end

    context 'when a serial record indicated from 949t' do
      subject { described_class.new(item_type: 'PERIODSPEC') }

      it { is_expected.to be_serial }
    end

    context 'when a microfilm record with leader6 and leader7 is not ab or as' do
      subject { described_class.new(item_type: 'MICROFORM', leader: '000000ax') }

      it { is_expected.not_to be_serial }
    end

    context 'when a microfilm record with leader6 and leader7 is ab' do
      subject { described_class.new(item_type: 'MICROFORM', leader: '000000ab') }

      it { is_expected.to be_serial }
    end

    context 'when a microfilm record with leader6 and leader7 is as' do
      subject { described_class.new(item_type: 'MICROFORM', leader: '000000as') }

      it { is_expected.to be_serial }
    end
  end

  describe '#forward_shelfkey' do
    subject { described_class.new(value: 'AB123 .C456 2000') }

    its(:forward_shelfkey) { is_expected.to eq('AB.0123.C456.2000') }
  end

  describe '#reverse_shelfkey' do
    subject { described_class.new(value: 'AB123 .C456 2000') }

    its(:reverse_shelfkey) { is_expected.to eq('PO.ZYXW.NVUT.XZZZ~') }
  end

  describe '#keymap' do
    subject { described_class.new(value: 'AB123 .C456 2000') }

    its(:keymap) do
      is_expected.to eq(
        {
          'call_number' => 'AB123 .C456 2000',
          'forward_key' => 'AB.0123.C456.2000',
          'reverse_key' => 'PO.ZYXW.NVUT.XZZZ~'
        }
      )
    end
  end
end
