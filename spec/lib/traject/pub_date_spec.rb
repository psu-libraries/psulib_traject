# frozen_string_literal: true

RSpec.describe 'From psulib_marc.rb' do
  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'process_publication_date' do
    let(:fixture_path) { './spec/fixtures' }

    it "works when there's no date information" do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      result = @indexer.map_record(@empty_record)
      expect(result['pub_date_sort_itsi']).to be_nil
    end

    it 'pulls out 008 date_type s' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first)
      expect(result['pub_date_sort_itsi']).to contain_exactly 2002
    end

    it 'uses start date for date_type c continuing resource' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'date_type_c.marc')).to_a.first)
      expect(result['pub_date_sort_itsi']).to contain_exactly 2006
    end

    it 'returns nil when the records really got nothing' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'emptyish_record.marc')).to_a.first)
      expect(result['pub_date_sort_itsi']).to be_nil
    end

    it "estimates with a single 'u'" do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'date_with_u.marc')).to_a.first)
      # was 184u as date1 on a continuing resource. For continuing resources,
      # we take the first date. And need to deal with the u.
      expect(result['pub_date_sort_itsi']).to contain_exactly 1845
    end

    it 'resorts to 264|*1|c' do
      record = MARC::Reader.new(File.join(fixture_path, 'date_resort_to_260.marc')).to_a.first
      record.append(MARC::DataField.new('264', '', '1', %w[c 1981]))
      result = @indexer.map_record(record)
      expect(result['pub_date_sort_itsi']).to contain_exactly 1981
    end

    it 'resorts to 260c' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'date_resort_to_260.marc')).to_a.first)
      expect(result['pub_date_sort_itsi']).to contain_exactly 1980
    end

    it 'works with date type r missing date2' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'date_type_r_missing_date2.marc')).to_a.first)
      expect(result['pub_date_sort_itsi']).to contain_exactly 1957
    end

    it "works correctly with date type 'n', it should resort to 264" do
      record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = record['008'].value
      val[6] = 'n'
      record['008'].value = val
      record.append(MARC::DataField.new('264', '', '1', %w[c 1981]))

      result = @indexer.map_record(record)
      expect(result['pub_date_sort_itsi']).to contain_exactly 1981
    end

    it "works correctly with date type 'q'" do
      record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = record['008'].value
      val[6] = 'q'
      val[7..10] = '191u'
      val[11..14] = '191u'
      record['008'].value = val

      result = @indexer.map_record(record)
      # Date should be date1 + date2 / 2 = (1910 + 1919) / 2 = 1914
      expect(result['pub_date_sort_itsi']).to contain_exactly 1914
    end

    it "works correctly with date type 'q', date2 should not be smaller than date1, it should check_elsewhere" do
      record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = record['008'].value
      val[6] = 'q'
      val[7..10] = '191u'
      val[11..14] = '190u'
      record['008'].value = val

      result = @indexer.map_record(record)
      expect(result['pub_date_sort_itsi']).to contain_exactly 2002
    end

    it "works correctly with date type 'q', it should not find a date when the difference between date1 and date2 is "\
       'bigger than the ESTIMATE_TOLERANCE and no 264 or 260 exists' do
      record = MARC::Reader.new(File.join(fixture_path, 'date_008_only.mrc')).to_a.first
      val = record['008'].value
      val[6] = 'q'
      val[7..10] = '19uu'
      val[11..14] = '19uu'
      record['008'].value = val

      result = @indexer.map_record(record)
      expect(result['pub_date_sort_itsi']).to be_nil
    end
  end
end
