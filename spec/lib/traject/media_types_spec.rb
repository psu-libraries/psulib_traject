# frozen_string_literal: true

RSpec.describe 'Media types spec:' do
  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'process_media_types' do
    let(:fixture_path) { './spec/fixtures' }

    it 'works with empty record, return empty media type' do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      result = @indexer.map_record(@empty_record)
      expect(result['media_type_facet']).to be_nil
    end

    it 'correctly sets 949a media types' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_949a.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'Blu-ray', 'DVD'
    end

    it 'correctly sets media type as Microfilm/Microfiche from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_0.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'Microfilm/Microfiche'
    end

    it 'correctly sets media type as Photo from 007' do
      @record = MARC::Reader.new(File.join(fixture_path, 'media_007_1.mrc')).to_a.first
      val = @record['007'].value
      val[0] = 'k'
      val[1] = 'h'
      @record['007'].value = val
      result = @indexer.map_record(@record)
      expect(result['media_type_facet']).to contain_exactly 'Photo'
    end

    it 'correctly sets media type as Wire recording from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_1.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'Wire recording'
    end

    it 'correctly sets media type as 78 rpm disc from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_3.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly '78 rpm disc'
    end

    it 'correctly sets media type as Videocassette (Beta) from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_4.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'Videocassette (Beta)'
    end

    it 'correctly sets media type as Other video from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_other.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'Other video'
    end

    it 'correctly sets media type as DVD from 538a' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_538a.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'DVD', 'Blu-ray'
    end

    it 'correctly sets media types from 300' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_300.mrc')).to_a.first)
      expect(result['media_type_facet']).to contain_exactly 'MPEG-4', 'Piano/Organ roll', 'Video CD', 'Microfilm/Microfiche'
    end
  end
end
