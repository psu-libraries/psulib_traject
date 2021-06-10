# frozen_string_literal: true

RSpec.describe MarcMediaTypeProcessor do
  subject { result['media_type_facet'] }

  let(:result) { indexer.map_record(MARC::Reader.new(File.join('./spec/fixtures', record)).to_a.first) }

  describe '#resolve' do
    context 'with an empty record' do
      let(:empty_record) do
        MARC::Record.new.tap do |record|
          record.append(MARC::ControlField.new('001', '000000000'))
        end
      end
      let(:result) { indexer.map_record(empty_record) }

      it { is_expected.to be_nil }
    end

    context 'with 949a media types' do
      let(:record) { 'media_949a.mrc' }

      it { is_expected.to contain_exactly('Blu-ray', 'DVD') }
    end

    context 'with media type as Microfilm/Microfiche from 007' do
      let(:record) { 'media_007_0.mrc' }

      it { is_expected.to be_nil }
    end

    context 'with media type as Wire recording from 007' do
      let(:record) { 'media_007_1.mrc' }

      it { is_expected.to contain_exactly 'Wire recording' }
    end

    context 'with media type as 78 rpm disc from 007' do
      let(:record) { 'media_007_3.mrc' }

      it { is_expected.to contain_exactly '78 rpm disc' }
    end

    context 'with media type as Videocassette (Beta) from 007' do
      let(:record) { 'media_007_4.mrc' }

      it { is_expected.to contain_exactly 'Videocassette (Beta)' }
    end

    context 'with media type as Other video from 007' do
      let(:record) { 'media_007_other.mrc' }

      it { is_expected.to contain_exactly 'Other video' }
    end

    context 'with media type as DVD from 538a' do
      let(:record) { 'media_538a.mrc' }

      it { is_expected.to contain_exactly 'DVD', 'Blu-ray' }
    end

    context 'with media types from 300' do
      let(:record) { 'media_300.mrc' }

      it { is_expected.to contain_exactly 'MPEG-4', 'Piano/Organ roll', 'Video CD' }
    end

    context 'with a CD based on 300' do
      let(:record) { '300_cd.mrc' }

      it { is_expected.to contain_exactly 'CD' }
    end

    context 'with vinyl based on 300' do
      let(:record) { '300_vinyl.mrc' }

      it { is_expected.to contain_exactly 'Vinyl disc' }
    end
  end

  describe '#resolve_007' do
    subject { described_class.new(record, access_facet).resolve_007 }

    let(:record) do
      MARC::Record.new.tap do |record|
        record.append(MARC::ControlField.new('007', value))
      end
    end

    let(:access_facet) { [] }

    context 'when Slide' do
      let(:value) { 'gs' }

      it { is_expected.to contain_exactly('Slide') }
    end

    context 'when Photo' do
      let(:value) { 'kh' }

      it { is_expected.to contain_exactly('Photo') }
    end

    context 'when Film' do
      let(:value) { 'm' }

      it { is_expected.to contain_exactly('Film') }
    end

    context 'when Remote-sensing image' do
      let(:value) { 'r' }

      it { is_expected.to contain_exactly('Remote-sensing image') }
    end

    context 'when Cylinder' do
      let(:value) { 'se' }
      let(:access_facet) { ['In the Library'] }

      it { is_expected.to contain_exactly('Cylinder') }
    end

    context 'when Audiocassette' do
      let(:value) { 's     j' }
      let(:access_facet) { ['In the Library'] }

      it { is_expected.to contain_exactly('Audiocassette') }
    end

    context 'when Piano/Organ roll' do
      let(:value) { 'sq' }
      let(:access_facet) { ['In the Library'] }

      it { is_expected.to contain_exactly('Piano/Organ roll') }
    end

    context 'when we cannot determine' do
      let(:value) { 'sx' }
      let(:access_facet) { ['In the Library'] }

      it { is_expected.to contain_exactly(nil) }
    end
  end

  describe '#resolve_300a' do
    subject { described_class.new(record, []).resolve_300a }

    let(:record) do
      MARC::Record.new.tap do |record|
        record.append(MARC::DataField.new('300', '', '', ['a', 'remote-sensing image']))
      end
    end

    it { is_expected.to contain_exactly('Remote-sensing image') }
  end
end
