# frozen_string_literal: true

RSpec.describe PsulibTraject::CallNumber do
  subject { described_class.new(
    value: nil,
    classification: nil,
    location: nil,
    item_type: item_type,
    leader: leader
  ) }

  context 'when not a serial record' do
    let(:item_type) { 'NOT_SERIAL' }
    let(:leader) { 'NOT_CARE' }

    it { is_expected.not_to be_serial }
  end

  context 'when a serial record indicated from 949t' do
    let(:item_type) { 'PERIODSPEC' }
    let(:leader) { 'NOT_CARE' }

    it { is_expected.to be_serial }
  end

  context 'when a microfilm record with leader6 and leader7 is not ab or as' do
    let(:item_type) { 'MICROFORM' }
    let(:leader) { '000000ax' }

    it { is_expected.not_to be_serial }
  end

  context 'when a microfilm record with leader6 and leader7 is ab' do
    let(:item_type) { 'MICROFORM' }
    let(:leader) { '000000ab' }

    it { is_expected.to be_serial }
  end


  context 'when a microfilm record with leader6 and leader7 is as' do
    let(:item_type) { 'MICROFORM' }
    let(:leader) { '000000as' }

    it { is_expected.to be_serial }
  end
end
