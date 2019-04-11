# frozen_string_literal: true

require_relative '../../../lib/traject/psulib_marc'

RSpec.describe 'From psulib_marc.rb' do
  describe 'process_hierarchy' do
    before(:all) do
      @subject610 = { '600' => { 'ind1' => '', 'ind2' => '5', 'subfields' => [{ 'a' => 'Exclude' }] } }
      @subject600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 't' => 'Title.' }, { 'v' => 'split genre' }, { 'd' => '2015' }, { '2' => 'special' }] } }
      @subject630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'z' => "don't ignore" }, { 't' => 'TITLE.' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@subject610, @subject600, @subject630])
      @subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz')
      @vocab_subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz', ['vocab'])
      @special_subjects = process_hierarchy(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz', ['special'])
    end
    describe 'when an optional vocabulary limit is not provided' do
      it 'excludes subjects without 0 in the 2nd indicator' do
        expect(@subjects).not_to include('Exclude')
        expect(@subjects).not_to include('Also Exclude')
      end

      it 'only separates v,x,y,z with em dash, strips punctuation' do
        expect(@subjects).to include("John. Title#{SEPARATOR}split genre 2015")
        expect(@subjects).to include("Fiction#{SEPARATOR}1492#{SEPARATOR}don't ignore TITLE")
      end
    end

    describe 'when a vocabulary limit is provided' do
      it 'excludes headings missing a subfield 2 or part of a different vocab' do
        expect(@vocab_subjects).to eq []
      end
      it 'only includes the heading from a matching subfield 2 value' do
        expect(@special_subjects).to eq ["John. Title#{SEPARATOR}split genre 2015"]
      end
    end
  end

  describe 'process_subject_topic_facet' do
    before(:all) do
      @subject600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 'x' => 'Join' }, { 't' => 'Title' }, { 'd' => '2015' }] } }
      @subject630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'z' => "don't ignore" }, { 'v' => 'split genre' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@subject600, @subject630])
      @subjects = process_subject_topic_facet(@sample_marc, '600|*0|abcdfklmnopqrtvxyz:630|*0|adfgklmnoprstvxyz')
    end

    it 'trims punctuation' do
      expect(@subjects).to include('John')
    end

    it 'includes subjects split along v, x, y and z' do
      expect(@subjects).to include('Join Title 2015')
      expect(@subjects).to include('1492')
      expect(@subjects).to include('split genre')
      expect(@subjects).to include('Fiction')
      expect(@subjects).to include("don't ignore")
    end
  end

  describe 'process_genres' do
    before(:all) do
      @genre650 = { '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'v' => 'Maps' }, { 'z' => 'Tippah County' }] } }
      @genre655_fast = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Fiction films' }, { 'b' => '1900' }, { '2' => 'fast' }, { 'z' => 'Germany' }] } }
      @genre655_lcgft = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Drama.' }, { '2' => 'lcgft' }] } }
      @genre655_aat = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Novels' }, { '2' => 'aat' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@genre650, @genre655_fast, @genre655_lcgft, @genre655_aat])
      @genres = process_genre(@sample_marc, '655|*0|abcvxyz:655|*7|abcvxyz')
    end

    it 'limits 655 to fast and lcgft genres' do
      expect(@genres).to include('Fiction films 1900 Germany')
      expect(@genres).to include('Drama')
    end
  end

  describe 'process_publication_date' do
    let(:fixture_path) { './spec/fixtures' }

    it "works when there's no date information" do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      expect(process_publication_date(@empty_record)).to be_nil
    end

    it 'pulls out 008 date_type s' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      expect(process_publication_date(@record)).to eq 2002
    end

    it 'uses start date for date_type c continuing resource' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_type_c.marc')).to_a.first
      expect(process_publication_date(@record)).to eq 2006
    end

    it 'returns nil when the records really got nothing' do
      @record = MARC::Reader.new(File.join(fixture_path, 'emptyish_record.marc')).to_a.first
      expect(process_publication_date(@record)).to be_nil
    end

    it "estimates with a single 'u'" do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_with_u.marc')).to_a.first
      # was 184u as date1 on a continuing resource. For continuing resources,
      # we take the first date. And need to deal with the u.
      expect(process_publication_date(@record)).to eq 1845
    end

    it 'resorts to 264|*1|c' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_resort_to_260.marc')).to_a.first
      @record.append(MARC::DataField.new('264', '', '1', %w[c 1981]))
      expect(process_publication_date(@record)).to eq 1981
    end

    it 'resorts to 260c' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_resort_to_260.marc')).to_a.first
      expect(process_publication_date(@record)).to eq 1980
    end

    it 'works with date type r missing date2' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_type_r_missing_date2.marc')).to_a.first
      expect(process_publication_date(@record)).to eq 1957
    end

    it "works correctly with date type 'n', it should resort to 264" do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = @record['008'].value
      val[6] = 'n'
      @record['008'].value = val
      @record.append(MARC::DataField.new('264', '', '1', %w[c 1981]))

      expect(process_publication_date(@record)).to eq 1981
    end

    it "works correctly with date type 'q'" do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = @record['008'].value
      val[6] = 'q'
      val[7..10] = '191u'
      val[11..14] = '191u'
      @record['008'].value = val

      # Date should be date1 + date2 / 2 = (1910 + 1919) / 2 = 1914
      expect(process_publication_date(@record)).to eq 1914
    end

    it "works correctly with date type 'q', date2 should not be smaller than date1, it should check_elsewhere" do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_008.marc')).to_a.first
      val = @record['008'].value
      val[6] = 'q'
      val[7..10] = '191u'
      val[11..14] = '190u'
      @record['008'].value = val

      expect(process_publication_date(@record)).to eq 2002
    end

    it "works correctly with date type 'q', it should not find a date when the difference between date1 and date2 is "\
       'bigger than the ESTIMATE_TOLERANCE and no 264 or 260 exists' do
      @record = MARC::Reader.new(File.join(fixture_path, 'date_008_only.mrc')).to_a.first
      val = @record['008'].value
      val[6] = 'q'
      val[7..10] = '19uu'
      val[11..14] = '19uu'
      @record['008'].value = val

      expect(process_publication_date(@record)).to be_nil
    end
  end
end
