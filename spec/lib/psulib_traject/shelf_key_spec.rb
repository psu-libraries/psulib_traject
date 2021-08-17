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

    its(:forward) { is_expected.to be_a(PsulibTraject::ShelfKey::NullKey) }
    its(:reverse) { is_expected.to be_a(PsulibTraject::ShelfKey::NullKey) }
  end

  context 'with lower-case letters in the middle of a cutter' do
    let(:call_number) { 'LD4481.P8kG45 2008' }

    its(:forward) { is_expected.to eq('LD.4481.P810.G45--2008') }
    its(:reverse) { is_expected.to eq('EM.VVRY.ARYZ.JVU--XZZR~') }
  end

  context 'with lower-case letters at the end of a cutter' do
    let(:call_number) { 'PZ7.H56774Fou 2014' }

    its(:forward) { is_expected.to eq('PZ.0007.H56774.F1420--2014') }
    its(:reverse) { is_expected.to eq('A0.ZZZS.IUTSSV.KYVXZ--XZYV~') }
  end

  context 'with colons in a cutter' do
    let(:call_number) { 'G3824.S8:2P4E635 2017 .P4' }

    its(:forward) { is_expected.to eq('G..3824.S8.0002.P4.E635--2017P0004') }
    its(:reverse) { is_expected.to eq('J..WRXV.7R.ZZZX.AV.LTWU--XZYSAZZZV~') }
  end

  context 'with three-letter LC classifications' do
    let(:call_number) { 'KJD.In8i' }

    its(:forward) { is_expected.to eq('KJD0000.I13808') }
    its(:reverse) { is_expected.to eq('FGMZZZZ.HYWRZR~') }
  end
end
