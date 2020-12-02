# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Macros spec:' do
  let(:leader) { '1234567890' }

  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe '#extract_link_data' do
    context 'A record where indicator 2 is 0 and magic word is not in one of the label subfields' do
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

    context 'A record where indicator 1 is 4, indicator 2 is blank and magic word is not in one of the label subfields' do
      let(:url_856_2) do
        { '856' => { 'ind1' => '4', 'ind2' => '', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                            '5d' },
                                                                  { 'z' => 'This text is irrelevant' }] } }
      end
      let(:result_1) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_2], 'leader' => leader)) }

      it 'produces a fulltext link' do
        expect(result_1['full_links_struct']).to match ['{"text":"scholarsphere.psu.edu","url":"https://scholarsphere.ps'\
                                                        'u.edu/files/02870v85d"}']
      end
    end

    context 'A record with an indicator 2 of 0 and magic word is in one of the label subfields' do
      let(:url_856_3) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                     'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                     'ml' },
                                                                   { '3' => 'Carrots executive summary peas' }] } }
      end
      let(:result_3) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_3], 'leader' => leader)) }

      it 'produces a partial link' do
        expect(result_3['partial_links_struct']).to match ['{"text":"library.columbia.edu","url":"http://library.columbi'\
                                                           'a.edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_'\
                                                           'archives.html"}']
      end
    end

    context 'A record with an indicator 1 of 4, indicator 2 is blank and magic word is in one of the label subfields' do
      let(:url_856_7) do
        { '856' => { 'ind1' => '4', 'ind2' => '', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                     'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                     'ml' },
                                                                  { '3' => 'Carrots executive summary peas' }] } }
      end
      let(:result_3) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_7], 'leader' => leader)) }

      it 'produces a partial link' do
        expect(result_3['partial_links_struct']).to match ['{"text":"library.columbia.edu","url":"http://library.columbia.'\
                                                         'edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_arch'\
                                                         'ives.html"}']
      end
    end

    context 'A record with multiple 856s, one with ind2 of 1 and other with ind2 2' do
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

      it 'produces 1 supplemental link and 1 partial link' do
        expect(result_5['partial_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2'\
                                                           '/MilitaryReview/mrpast2.asp"}']
        expect(result_5['suppl_links_struct']).to match ['{"text":"calldp.leavenworth.army.mil","url":"http://calldp.lea'\
                                                         'venworth.army.mil/"}']
      end
    end

    context 'A record with a fulltext link to Summon' do
      let(:url_856_6) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'http://SK8ES4MC2L.search.serialssolutions.c'\
                              'om/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Conference%20on%20Mining%20Softw'\
                              'are%20Repositories%20%3A%20proceedings%20%3A%20May%2031%20-%20June%201%2C%202014%2C%20Hyd'\
                              'erabad%2C%20India' }] } }
      end
      let(:result_6) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_6], 'leader' => leader)) }

      it 'produces a fulltext link with text that drops summon\'s sub-domains' do
        expect(result_6['full_links_struct']).to match ['{"text":"serialssolutions.com","url":"http://SK8ES4MC2L.search.'\
                                          'serialssolutions.com/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Co'\
                                          'nference%20on%20Mining%20Software%20Repositories%20%3A%20proceedings%20%3A%20'\
                                          'May%2031%20-%20June%201%2C%202014%2C%20Hyderabad%2C%20India"}']
      end
    end

    context 'A record with a url prefix is not http or https' do
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
  end

  describe '#process_genre' do
    let(:genre650) { { '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'v' => 'Maps' }, { 'z' => 'Tippah County' }] } } }
    let(:genre655_fast) { { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Fiction films' }, { 'b' => '1900' }, { '2' => 'fast' }, { 'z' => 'Germany' }] } } }
    let(:genre655_lcgft) { { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Drama.' }, { '2' => 'lcgft' }] } } }
    let(:genre655_aat) { { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Novels' }, { '2' => 'aat' }] } } }
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [genre650, genre655_fast, genre655_lcgft, genre655_aat], 'leader' => leader)) }

    it 'limits 655 to fast and lcgft genres' do
      expect(result['genre_display_ssm']).to include('Fiction films 1900 Germany')
      expect(result['genre_display_ssm']).to include('Drama')
    end
  end

  describe '#extract_oclc_number' do
    let(:oclc_no_035_1) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCoLC)154806744' }] } } }
    let(:oclc_no_035_2) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(ocn)239422053' }] } } }
    let(:oclc_no_035_3) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(ocm)40777018' }] } } }
    let(:oclc_no_035_4) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)70197573' }] } } }
    let(:oclc_no_035_5) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => 'LIAS92' }] } } }
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [oclc_no_035_1, oclc_no_035_2, oclc_no_035_3, oclc_no_035_4, oclc_no_035_5], 'leader' => leader)) }

    context 'when there is no 035' do
      it 'does not map record' do
        @empty_record = MARC::Record.new
        @empty_record.append(MARC::ControlField.new('001', '000000000'))
        result = @indexer.map_record(@empty_record)
        expect(result['oclc_number_ssim']).to be_nil
      end
    end

    context 'when 035 field includes \"OCoLC\"' do
      it 'maps the oclc number' do
        expect(result['oclc_number_ssim']).to include('154806744')
      end
    end

    context 'when 035 field includes \"ocn\"' do
      it 'maps the oclc number' do
        expect(result['oclc_number_ssim']).to include('239422053')
      end
    end

    context 'when 035 field includes \"ocm\"' do
      it 'maps the oclc number' do
        expect(result['oclc_number_ssim']).to include('40777018')
      end
    end

    context 'when 035 field includes \"OCLC\"' do
      it 'maps the oclc number' do
        expect(result['oclc_number_ssim']).to include('70197573')
      end
    end

    context 'when 035 field does not include any of the OCLC prefixes' do
      it 'ignores the 035 value' do
        expect(result['oclc_number_ssim']).to eq %w[154806744 239422053 40777018 70197573]
      end
    end
  end

  describe '#extract_hathi_data' do
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [oclc], 'leader' => leader)) }

    context 'when a record does not have a match in the overlap reports' do
      let(:oclc) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)99999999' }] } } }

      it 'does not produce a hathitrust_struct' do
        expect(result['hathitrust_struct']).to be_nil
      end
    end

    context 'when a record has a match in the overlap mono report' do
      let(:oclc) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)100000499' }] } } }

      it 'does maps the ht_id' do
        expect(result['hathitrust_struct']).to match ['{"ht_id":"mdp.39015069374455","access":"deny"}']
      end
    end

    context 'when a record has a match in the overlap multi report' do
      let(:oclc) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)100000391' }] } } }

      it 'does maps the ht_id' do
        expect(result['hathitrust_struct']).to match ['{"ht_bib_key":"012292266","access":"allow"}']
      end
    end

    context 'when a record has an oclc with leading zeros' do
      let(:oclc) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)00100000391' }] } } }

      it 'finds a match after stripping the leading zeros' do
        expect(result['hathitrust_struct']).to match ['{"ht_bib_key":"012292266","access":"allow"}']
      end
    end
  end

  describe '#hathi_to_hash' do
    let(:result) { @indexer.hathi_to_hash(ht_format) }

    context 'for hathi records with mono item type' do
      let(:ht_format) { 'mono' }

      it 'produces hathi data ' do
        expect(result['1000']).to match [{ ht_id: 'wu.89030498562', access: 'deny' }]
      end

      it 'prefers the record with allow access if there are multiple copies with same oclc' do
        expect(result['1000021']).to match [{ ht_id: 'uc1.b3547182', access: 'allow' }]
      end

      it 'selects only one deny copy if there are multiple copies with same oclc' do
        expect(result['155131850']).to match [{ ht_id: 'mdp.39076002651854', access: 'deny' }]
      end
    end

    context 'for hathi records with multi/serial item type' do
      let(:ht_format) { 'multi' }

      it 'produces hathi data correctly' do
        expect(result['100000391']).to match [{ ht_bib_key: '012292266', access: 'allow' }]
      end

      it 'prefers the record with deny access if there are multiple copies with same oclc' do
        expect(result['1000061']).to match [{ ht_bib_key: '12345', access: 'deny' }]
      end

      it 'selects only one deny copy if there are multiple copies with same oclc' do
        expect(result['1000310']).to match [{ ht_bib_key: '009911637', access: 'deny' }]
      end
    end
  end

  describe '#exclude_locations' do
    it 'filters excluded locations out' do
      location_1 = { '949' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'l' => 'DOCUSMF-DN' }] } }
      location_2 = { '949' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'l' => 'RESERVE-HN' }] } }
      location_3 = { '949' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'l' => 'AVAIL_SOON' }] } }
      result = @indexer.map_record(MARC::Record.new_from_hash('fields' => [location_1, location_2, location_3], 'leader' => leader))

      expect(result['location_facet']).to eq ['Dickinson Law (Carlisle) - Lower Level - Gov Doc MF', 'on course reserve at Hazleton']
    end
  end
end
