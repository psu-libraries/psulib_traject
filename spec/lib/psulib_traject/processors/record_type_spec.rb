# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::RecordType do
  let(:current_formats) { [] }
  let(:microfilm) { Traject::TranslationMap.new('formats_949t')['MICROFORM'] }

  describe '::call' do
    subject { described_class.call(record: record, current_formats: current_formats) }

    let(:record) { OpenStruct.new(leader: '      ta') }

    context 'with existing non-microfilm formats' do
      let(:current_formats) do
        Traject::TranslationMap.new('formats_949t')
          .hash
          .reject { |k, _v| k == 'MICROFORM' }
          .values
          .sample(2)
      end

      it { is_expected.to eq(current_formats) }
    end

    context 'with an existing microfilm format' do
      let(:microfilm) { Traject::TranslationMap.new('formats_949t')['MICROFORM'] }
      let(:current_formats) { [microfilm] }

      it { is_expected.to contain_exactly(microfilm, 'Archives/Manuscripts') }
    end
  end

  describe '#resolve' do
    subject { described_class.new(record, current_formats).resolve }

    let(:record) { OpenStruct.new(leader: '      ta') }

    it { is_expected.to eq('Archives/Manuscripts') }
  end

  describe '#bibliographic_level' do
    subject { described_class.new(record, current_formats).bibliographic_level }

    context 'with b leader' do
      let(:record) { OpenStruct.new(leader: '       b') }

      it { is_expected.to eq('Journal/Periodical') }
    end

    context 'with s leader' do
      let(:record) { OpenStruct.new(leader: '       s') }

      it { is_expected.to eq('Journal/Periodical') }
    end

    context 'with c leader' do
      let(:record) { OpenStruct.new(leader: '       c') }

      it { is_expected.to eq('Archives/Manuscripts') }
    end

    context 'with d leader' do
      let(:record) { OpenStruct.new(leader: '       d') }

      it { is_expected.to eq('Book') }
    end

    context 'with empty leader' do
      let(:record) { OpenStruct.new(leader: '        ') }

      it { is_expected.to be_nil }
    end
  end

  describe '#thesis_or_book' do
    subject { described_class.new(record, current_formats).thesis_or_book }

    context 'with a matchin 008 field' do
      let(:record) do
        record = '00085cxm a2200049Ii 45000010005000000080030000051234150224t21052015cau dq x engmd'
        MARC::Reader.new(StringIO.new(record)).first
      end

      it { is_expected.to eq('Thesis/Dissertation') }
    end
  end
end
