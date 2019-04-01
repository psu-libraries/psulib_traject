# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Macros spec:' do
  let(:leader) { '1234567890' }

  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'A record with a fulltext link because of indicator 2 is 0' do
    let(:url_856_1) do
      { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                          '5d' },
                                                                 { 'z' => 'This text is irrelevant' }] } }
    end
    let(:result_1) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_1], 'leader' => leader)) }

    it 'produces a fulltext link' do
      expect(result_1['full_links_struct']).to match ['{"text":"scholarsphere.psu.edu","url":"https://scholarsphere.ps'\
                                                      'u.edu/files/02870v85d"}']
    end
  end

  describe 'A record without a magic word in one of the label subfields' do
    let(:url_856_2) do
      { '856' => { 'ind1' => '0', 'ind2' => '7', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                           '5d' },
                                                                 { '3' => 'Apples bananas' }] } }
    end
    let(:result_2) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_2], 'leader' => leader)) }

    it 'produces a fulltext link' do
      expect(result_2['full_links_struct']).to eq ['{"text":"scholarsphere.psu.edu","url":"https://scholarsphere.psu.e'\
                                                                                          'du/files/02870v85d"}']
    end
  end

  describe 'A record with an indicator 2 of 2 and magic word is in one of the label subfields' do
    let(:url_856_3) do
      { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                   'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                   'ml' },
                                                                 { '3' => 'Carrots executive summary peas' }] } }
    end
    let(:result_3) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_3], 'leader' => leader)) }

    it 'produces a supplemental link' do
      expect(result_3['suppl_links_struct']).to match ['{"text":"library.columbia.edu","url":"http://library.columbia.'\
                                                       'edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_arch'\
                                                       'ives.html"}']
    end
  end

  describe 'A record with an indicator 2 of 2 and magic word is not one of the label subfields' do
    let(:url_856_3a) do
      { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                   'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                   'ml' },
                                                                 { '3' => 'Carrots peas' }] } }
    end
    let(:result_3a) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_3a], 'leader' => leader)) }

    it 'produces a fulltext link' do
      expect(result_3a['full_links_struct']).to match ['{"text":"library.columbia.edu","url":"http://library.columbia.'\
                                                       'edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_arch'\
                                                       'ives.html"}']
    end
  end

  describe 'A record with a url prefix is not http or https' do
    let(:url_856_4) do
      { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'ftp://ppftpuser:welcome@ftp01.penguingroup.'\
                                                                   'com/BooksellersandMedia/Covers/2008_2009_New_Cover'\
                                                                   's/9780525953951.jpg' },
                                                                 { '3' => 'Cover image' }] } }
    end
    let(:result_4) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_4], 'leader' => leader)) }

    it 'doesn\'t produce any URL' do
      expect(result_4['full_links_struct']).to be_nil
      expect(result_4['partial_links_struct']).to be_nil
      expect(result_4['suppl_links_struct']).to be_nil
    end
  end

  describe 'A record with multiple 856s, one with ind2 of 1 and other with ind2 2, neither of which have no-fulltext '\
           'indicator word in a label subfield' do
    let(:url_856_5) do
      [
        { '856' =>
              { 'ind1' => '0', 'ind2' => '1', 'subfields' => [
                { 'u' => 'http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp' }
              ] } },
        { '856' =>
              { 'ind1' => '4', 'ind2' => '2', 'subfields' => [
                { 'u' => 'http://calldp.leavenworth.army.mil/' },
                { 'z' => 'Gateway to archives.' },
                { 'z' => 'URL does not work, Feb. 3, 2016.' }
              ] } }
      ]
    end
    let(:result_5) { @indexer.map_record(MARC::Record.new_from_hash('fields' => url_856_5, 'leader' => leader)) }

    it 'produces 2 fulltext links and 1 partial link' do
      expect(result_5['full_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2/Mi'\
                                                      'litaryReview/mrpast2.asp"}',
                                                      '{"text":"calldp.leavenworth.army.mil","url":"http://calldp.leav'\
                                                      'enworth.army.mil/"}']
      expect(result_5['partial_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2'\
                                                         '/MilitaryReview/mrpast2.asp"}']
    end
  end

  describe 'A record with a fulltext link to Summon' do
    let(:url_856_6) do
      { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://SK8ES4MC2L.search.serialssolutions.c'\
                            'om/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Conference%20on%20Mining%20Softw'\
                            'are%20Repositories%20%3A%20proceedings%20%3A%20May%2031%20-%20June%201%2C%202014%2C%20Hyd'\
                            'erabad%2C%20India' }] } }
    end
    let(:result_6) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_6], 'leader' => leader)) }

    it 'produces a fulltext link with text that drop summon\'s sub-domains' do
      expect(result_6['full_links_struct']).to match ['{"text":"serialssolutions.com","url":"http://SK8ES4MC2L.search.'\
                                        'serialssolutions.com/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Co'\
                                        'nference%20on%20Mining%20Software%20Repositories%20%3A%20proceedings%20%3A%20'\
                                        'May%2031%20-%20June%201%2C%202014%2C%20Hyderabad%2C%20India"}']
    end
  end

  describe 'access_facet' do
    let(:fixture_path) { './spec/fixtures' }

    it 'works with empty record, returns empty' do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      result = @indexer.map_record(@empty_record)
      expect(result['access_facet']).to be_nil
    end

    it 'produces In the Library and Online when a record has both an online copy and a physical copy' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_in_library.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'In the Library', 'Online'
    end

    it 'produces On Order when a record has a copy with an on-order location' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_on_order.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'On Order'
    end

    it 'produces In the Library and Online when a record has an online copy, a physical copy and an on-order copy' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_all.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'In the Library', 'Online'
    end

    it 'produces Other when a record has a 949m library code that is not listed' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_other.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'Other'
    end

    it 'empty when a record has a 949m library code ZREMOVED or XTERNAL' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_zremoved.mrc')).to_a.first)
      expect(result['access_facet']).to be_nil
    end
  end

  describe 'process_media_types' do
    let(:fixture_path) { './spec/fixtures' }

    it 'works with empty record, return empty media type' do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      result = @indexer.map_record(@empty_record)
      expect(result['media_type_facet_ssim']).to be_nil
    end

    it 'correctly sets 949a media types' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_949a.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Blu-ray', 'DVD'
    end

    it 'correctly sets media type as Microfilm/Microfiche from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_0.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Microfilm/Microfiche'
    end

    it 'correctly sets media type as Photo from 007' do
      @record = MARC::Reader.new(File.join(fixture_path, 'media_007_1.mrc')).to_a.first
      val = @record['007'].value
      val[0] = 'k'
      val[1] = 'h'
      @record['007'].value = val
      result = @indexer.map_record(@record)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Photo'
    end

    it 'correctly sets media type as Wire recording from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_1.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Wire recording'
    end

    it 'correctly sets media type as 78 rpm disc from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_3.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly '78 rpm disc'
    end

    it 'correctly sets media type as Videocassette (Beta) from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_4.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Videocassette (Beta)'
    end

    it 'correctly sets media type as Other video from 007' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_007_other.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'Other video'
    end

    it 'correctly sets media type as DVD from 538a' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_538a.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'DVD', 'Blu-ray'
    end

    it 'correctly sets media types from 300' do
      result = @indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'media_300.mrc')).to_a.first)
      expect(result['media_type_facet_ssim']).to contain_exactly 'MPEG-4', 'Piano/Organ roll', 'Video CD', 'Microfilm/Microfiche'
    end
  end
end
