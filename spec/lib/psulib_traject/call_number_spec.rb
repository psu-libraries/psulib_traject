# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::CallNumber do
  context "when value starts with 'Periodical'" do
    subject { described_class.new(value: 'Periodical Something') }

    it { is_expected.to be_periodical }
    it { is_expected.not_to be_newspaper }
    it { is_expected.not_to be_local }
    it { is_expected.not_to be_on_order }
    it { is_expected.to be_exclude }
  end

  context "when value starts with '^Periodical'" do
    subject { described_class.new(value: '^Periodical blah') }

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

  context "when value contains 'Newspaper'" do
    subject { described_class.new(value: 'Cool newspaper Thing') }

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

  context "when value starts with 'XX('" do
    subject { described_class.new(value: 'XX(asdf1234)') }

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

  describe '#solr_field' do
    subject { described_class.new(classification: 'LCPER') }

    its(:solr_field) { is_expected.to eq('call_number_lc_ssm') }
  end

  describe '#forward_shelfkey_field' do
    subject { described_class.new(classification: 'DEWEY') }

    its(:forward_shelfkey_field) { is_expected.to eq('forward_dewey_shelfkey') }
  end

  describe '#reverse_shelfkey_field' do
    subject { described_class.new(classification: 'DEWEY') }

    its(:reverse_shelfkey_field) { is_expected.to eq('reverse_dewey_shelfkey') }
  end

  describe '#not_browsable?' do
    context 'when an invalid LC call number' do
      subject { described_class.new(value: 'INVALID LC', classification: 'LC') }

      it { is_expected.to be_not_browsable }
    end

    context 'when an invalid Dewey call number' do
      subject { described_class.new(value: 'Microfilm E243', classification: 'DEWEY') }

      it { is_expected.to be_not_browsable }
    end

    context 'when a call number that is not LC or Dewey' do
      subject { described_class.new(value: 'AB123 .C456 2000', classification: 'ASIS') }

      it { is_expected.to be_not_browsable }
    end
  end

  describe '#keymap' do
    subject { described_class.new(value: 'AB123 .C456 2000', classification: 'LC') }

    its(:keymap) do
      is_expected.to eq(
        {
          call_number: 'AB123 .C456 2000',
          classification: 'LC',
          forward_key: 'AB.0123.C456.2000',
          reverse_key: 'PO.ZYXW.NVUT.XZZZ~'
        }
      )
    end
  end
end
