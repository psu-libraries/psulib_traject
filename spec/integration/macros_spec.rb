# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Macros' do
  let(:leader) { '1234567890' }

  describe '#extract_link_data' do
    context 'A record where indicator 2 is 0 and magic word is not in one of the label subfields' do
      let(:url_856_1) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                            '5d' },
                                                                   { 'z' => 'This is a note' }] } }
      end
      let(:result_1) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_1], 'leader' => leader)) }

      it 'produces a fulltext link' do
        expect(result_1['full_links_struct']).to match ['{"prefix":"","text":"scholarsphere.psu.edu","url":"https://scholarsphere.ps'\
                                                        'u.edu/files/02870v85d","notes":"This is a note"}']
      end
    end

    context 'A record where indicator 1 and 2 is blank and magic word is not in one of the label subfields' do
      let(:url_856_2) do
        { '856' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                            '5d' },
                                                                 { 'z' => 'This is a note' }] } }
      end
      let(:result_1) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_2], 'leader' => leader)) }

      it 'produces a fulltext link' do
        expect(result_1['full_links_struct']).to match ['{"prefix":"","text":"scholarsphere.psu.edu","url":"https://scholarsphere.ps'\
                                                        'u.edu/files/02870v85d","notes":"This is a note"}']
      end
    end

    context 'A record where indicator 1 is not blank, indicator 2 is blank and magic word is not in one of the label subfields' do
      let(:url_856_2) do
        { '856' => { 'ind1' => '4', 'ind2' => '', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v8'\
                                                                            '5d' },
                                                                  { 'z' => 'This is a note' }] } }
      end
      let(:result_1) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_2], 'leader' => leader)) }

      it 'produces a fulltext link' do
        expect(result_1['full_links_struct']).to match ['{"prefix":"","text":"scholarsphere.psu.edu","url":"https://scholarsphere.ps'\
                                                        'u.edu/files/02870v85d","notes":"This is a note"}']
      end
    end

    context 'A record with an indicator 2 of 0 and magic word is in one of the label subfields' do
      let(:url_856_3) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                     'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                     'ml' },
                                                                   { '3' => 'Carrots executive summary peas' }] } }
      end
      let(:result_3) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_3], 'leader' => leader)) }

      it 'produces a partial link' do
        expect(result_3['partial_links_struct']).to match ['{"prefix":"Carrots executive summary peas","text":"library.columbia.edu","url":"http://library.columbi'\
                                                           'a.edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_'\
                                                           'archives.html","notes":""}']
      end
    end

    context 'A record with an indicator 2 of 1 and magic word is not in one of the label subfields' do
      let(:url_856_9) do
        { '856' => { 'ind1' => '4', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://archive.org/details/facultybulletinp00penn' },
                                                                   { '3' => 'v.19-20 Sept.1939-May 1941' }] } }
      end

      let(:result_9) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_9], 'leader' => leader)) }

      it 'only produces partial links, no full links' do
        expect(result_9['full_links_struct']).to be_nil
        expect(result_9['partial_links_struct']).to match ['{"prefix":"v.19-20 Sept.1939-May 1941","text":"archive.org",'\
                                                                   '"url":"http://archive.org/details/facultybulletinp00penn","notes":""}']
      end
    end

    context 'A record with an indicator 2 of 1 and magic word is in one of the label subfields' do
      let(:url_856_7) do
        { '856' => { 'ind1' => '4', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/library'\
                                                                     'web/indiv/ccoh/our_work/how_to_use_the_archives.ht'\
                                                                     'ml' },
                                                                   { '3' => 'Just prefix' }] } }
      end
      let(:result_3) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_7], 'leader' => leader)) }

      it 'produces a partial link' do
        expect(result_3['partial_links_struct']).to match ['{"prefix":"Just prefix","text":"library.columbia.edu","url":"http://library.columbia.'\
                                                         'edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_arch'\
                                                         'ives.html","notes":""}']
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
      let(:result_5) { indexer.map_record(MARC::Record.new_from_hash('fields' => url_856_5, 'leader' => leader)) }

      it 'produces 1 supplemental link and 1 partial link' do
        expect(result_5['partial_links_struct']).to match ['{"prefix":"","text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2'\
                                                           '/MilitaryReview/mrpast2.asp","notes":""}']
        expect(result_5['suppl_links_struct']).to match ['{"prefix":"","text":"calldp.leavenworth.army.mil","url":"http://calldp.lea'\
                                                         'venworth.army.mil/","notes":"Gateway to archives. URL does not work, Feb. 3, 2016."}']
      end
    end

    context 'A record with a fulltext link to Summon' do
      let(:url_856_6) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'http://SK8ES4MC2L.search.serialssolutions.c'\
                              'om/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Conference%20on%20Mining%20Softw'\
                              'are%20Repositories%20%3A%20proceedings%20%3A%20May%2031%20-%20June%201%2C%202014%2C%20Hyd'\
                              'erabad%2C%20India' }] } }
      end
      let(:result_6) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_6], 'leader' => leader)) }

      it 'produces a fulltext link with text that drops summon\'s sub-domains' do
        expect(result_6['full_links_struct']).to match ['{"prefix":"","text":"serialssolutions.com","url":"http://SK8ES4MC2L.search.'\
                                          'serialssolutions.com/?sid=sersol&SS_jc=TC0001341523&title=11th%20Working%20Co'\
                                          'nference%20on%20Mining%20Software%20Repositories%20%3A%20proceedings%20%3A%20'\
                                          'May%2031%20-%20June%201%2C%202014%2C%20Hyderabad%2C%20India","notes":""}']
      end
    end

    context 'A record with a url prefix is not http or https' do
      let(:url_856_4) do
        { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'ftp://ppftpuser:welcome@ftp01.penguingroup.'\
                                                                     'com/BooksellersandMedia/Covers/2008_2009_New_Cover'\
                                                                     's/9780525953951.jpg' },
                                                                   { '3' => 'Cover image' }] } }
      end
      let(:result_4) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_4], 'leader' => leader)) }

      it 'doesn\'t produce any URL' do
        expect(result_4['full_links_struct']).to be_nil
        expect(result_4['partial_links_struct']).to be_nil
        expect(result_4['suppl_links_struct']).to be_nil
      end
    end

    context 'A record with a url prefix that is not entirely lowercase' do
      let(:url_856_case_mismatch) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'HtTp://hdl.loc.gov/loc.gmd/g3894p.pm010090' },
                                                                   { 'z' => 'My Cool Note' }] } }
      end
      let(:result_case_mismatch) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_case_mismatch], 'leader' => leader)) }

      it 'produces link data' do
        expect(result_case_mismatch['full_links_struct']).to match ['{"prefix":"","text":"hdl.loc.gov",'\
                                                                    '"url":"HtTp://hdl.loc.gov/loc.gmd/g3894p.pm010090","notes":"My Cool Note"}']
      end
    end

    context 'A record with no url prefix and starts with "www."' do
      let(:url_856_case_mismatch) do
        { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'www.hdl.loc.gov/loc.gmd/g3894p.pm010090' },
                                                                   { 'z' => 'My Cool Note' }] } }
      end
      let(:result_case_mismatch) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_case_mismatch], 'leader' => leader)) }

      it 'produces link data' do
        expect(result_case_mismatch['full_links_struct']).to match ['{"prefix":"","text":"www.hdl.loc.gov",'\
                                                                    '"url":"http://www.hdl.loc.gov/loc.gmd/g3894p.pm010090","notes":"My Cool Note"}']
      end
    end

    context 'A record with a url that has all subfields for a prefix, label and notes' do
      let(:url_856_8) do
        { '856' => { 'ind1' => '4', 'ind2' => '0', 'subfields' => [{ 'u' => 'http://purl.access.gpo.gov/GPO/LPS47374' },
                                                                   { '3' => 'v.7' },
                                                                   { 'y' => 'Electronic resource (PDF)' },
                                                                   { 'y' => 'Electronic resource (PDF) 2' },
                                                                   { 'z' => 'Adobe Acrobat Reader required' },
                                                                   { 'z' => 'Another note' }] } }
      end

      let(:result_8) { indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_8], 'leader' => leader)) }

      it 'produce a link struct with a label, prefix and notes' do
        expect(result_8['full_links_struct']).to match ['{"prefix":"v.7","text":"Electronic resource (PDF)","url":"http://purl.access.gpo.gov/GPO/LPS47374",'\
                                          '"notes":"Adobe Acrobat Reader required Another note"}']
      end
    end
  end

  describe '#include_psu_theses_only' do
    let(:thesis_dept_699) do
      { '699' => { 'subfields' => [{ 'a' => 'Acoustics.' }] } }
    end

    context 'when a record has no 949t fields' do
      let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [thesis_dept_699], 'leader' => leader)) }

      it 'does not index the theses department data' do
        expect(result['thesis_dept_facet']).to be_nil
      end
    end

    context 'when a record does not have a PSU thesis code' do
      let(:code_949) do
        { '949' => { 'subfields' => [{ 'a' => 'Thesis 2011mOrr,A', 't' => 'THESIS-A' }] } }
      end

      let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [thesis_dept_699, code_949], 'leader' => leader)) }

      it 'does not index the theses department data' do
        expect(result['thesis_dept_facet']).to be_nil
      end
    end

    context 'when a record does have a PSU thesis code' do
      let(:code_949) do
        { '949' => { 'subfields' => [{ 'a' => 'Thesis 2011mOrr,A', 't' => 'THESIS-B' }] } }
      end

      let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [thesis_dept_699, code_949], 'leader' => leader)) }

      it 'indexes the theses department data' do
        expect(result['thesis_dept_facet']).to eq ['Acoustics']
      end
    end
  end

  describe '#process_genre' do
    let(:genre_fields) { [{ '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'v' => 'Maps' }, { 'z' => 'Tippah County' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Fiction films' }, { 'b' => '1900' }, { '2' => 'fast' }, { 'z' => 'Germany' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Drama.' }, { '2' => 'lcgft' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Novels' }, { '2' => 'aat' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Bogus' }, { '2' => 'bogus' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Periodicals' }, { '2' => 'rbgenr' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Rbbin' }, { '2' => 'rbbin' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Rbprov' }, { '2' => 'rbprov' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Rbpub' }, { '2' => 'rbpub' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Rbpri' }, { '2' => 'rbpri' }] } },
                          { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Rbmscv' }, { '2' => 'rbmscv' }] } }] }
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => genre_fields, 'leader' => leader)) }

    it 'limits 655 genres and separates multiple internal genres with a hyphen' do
      expect(result['genre_display_ssm']).to eq(['Fiction films - 1900 - Germany', 'Drama', 'Novels',
                                                 'Periodicals', 'Rbbin', 'Rbprov', 'Rbpub', 'Rbpri', 'Rbmscv'])
    end
  end

  describe '#extract_oclc_number' do
    let(:oclc_no_035_1) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCoLC)154806744' }] } } }
    let(:oclc_no_035_2) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(ocn)239422053' }] } } }
    let(:oclc_no_035_3) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(ocm)40777018' }] } } }
    let(:oclc_no_035_4) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => '(OCLC)70197573' }] } } }
    let(:oclc_no_035_5) { { '035' => { 'ind1' => '', 'ind2' => '', 'subfields' => [{ 'a' => 'LIAS92' }] } } }
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [oclc_no_035_1, oclc_no_035_2, oclc_no_035_3, oclc_no_035_4, oclc_no_035_5], 'leader' => leader)) }

    context 'when there is no 035' do
      it 'does not map record' do
        @empty_record = MARC::Record.new
        @empty_record.append(MARC::ControlField.new('001', '000000000'))
        result = indexer.map_record(@empty_record)
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
end
