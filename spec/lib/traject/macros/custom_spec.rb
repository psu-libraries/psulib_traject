# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Macros spec:' do
  let(:leader) { '1234567890' }

  let(:field) { 'full_links_struct' }
  let(:url_856) do
    { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v85d' },
                                                               { '3' => 'How to use the collection' }] } }
  end
  let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856], 'leader' => leader)) }

  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'A record with a fulltext link because of indicator 2 is 0' do
    let(:url_856_1) do
      { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v85d' },
                                                                 { 'z' => 'This text is irrelevant' }] } }
    end
    let(:result_1) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_1], 'leader' => leader)) }

    it 'produces a fulltext link' do
      expect(result_1[field]).to match ['{"text":"scholarsphere.psu.edu","url":"https://scholarsphere.psu.edu/files/02870v85d"}']
    end
  end

  describe 'A record without a magic word in one of the label subfields' do
    let(:url_856_2) do
      { '856' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'u' => 'https://scholarsphere.psu.edu/files/02870v85d' },
                                                                 { '3' => 'Apples bananas' }] } }
    end
    let(:result_2) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_2], 'leader' => leader)) }

    it 'produces a fulltext link' do
      expect(result_2[field]).to eq ['{"text":"scholarsphere.psu.edu","url":"https://scholarsphere.psu.edu/files/02870v85d"}']
    end
  end

  describe 'A record with an indicator 2 of 2 and magic word is in one of the label subfields' do
    let(:field) { 'suppl_links_struct' }
    let(:url_856_3) do
      { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://library.columbia.edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_archives.html' },
                                                                 { '3' => 'Carrots executive summary peas' }] } }
    end
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_3], 'leader' => leader)) }

    it 'produces a supplemental link' do
      expect(result[field]).to match ['{"text":"library.columbia.edu","url":"http://library.columbia.edu/content/libraryweb/indiv/ccoh/our_work/how_to_use_the_archives.html"}']
    end
  end

  describe 'A record with an indicator 2 of 2 and magic word is not in one of the label subfields' do
    let(:field) { 'suppl_links_struct' }
    let(:url_856_4) do
      { '856' => { 'ind1' => '0', 'ind2' => '2', 'subfields' => [{ 'u' => 'ftp://ppftpuser:welcome@ftp01.penguingroup.com/BooksellersandMedia/Covers/2008_2009_New_Covers/9780525953951.jpg' },
                                                                 { '3' => 'Cover image' }] } }
    end
    let(:result_4) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [url_856_4], 'leader' => leader)) }

    it 'doesn\'t produce any URL' do
      expect(result_4[field]).to be_nil
    end
  end

  describe 'A record with a lot of stuff' do
    let(:url_856_5) do
     [
          { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://calldp.leavenworth.army.mil/scripts/cqcgi.exe/@ss_prod.env?CQ_SAVE[CGI]=/scripts/cqcgi.exe/@ss_prod.env&CQ_MAIN=YES&CQ_LOGIN=YES&CQDC=Tue%20Jun%2017%202008%2015%3A29%3A03%20GMT-0400%20%28Eastern%20Daylight%20Time%29&CQ_SAVE[GIFs]=/rware/gif8&CQ_USER_NAME=96063898&CQ_PASSWORD=xxx&CQ_SAVE[CPU]=Intel&CQ_SAVE[Browser]=W3C&CQ_SAVE[BrowserVersion]=nav6up&CQ_SAVE[Base]=calldp.leavenworth.army.mil&CQ_SAVE[Home]=http%3A//calldp.leavenworth.army.mil/call_pub.html' },
                                                                 { 'z' => 'URL does not work, Feb. 3, 2016.' }]}},
          { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://purl.access.gpo.gov/GPO/LPS1465' }]}},
          { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp' }]}},
          { '856' => { 'ind1' => '4', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://calldp.leavenworth.army.mil/' }, { 'z' => 'Gateway to archives.' }, { 'z' => 'URL does not work, Feb. 3, 2016.' }]}},
          { '856' => { 'ind1' => '4', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://cgsc.cdmhost.com/cdm4/browse.php?CISOROOT=%2Fp124201coll1' }, { 'z' => 'Combined Arms Research Library Digital' }]}}
    ]
    end
    let(:result_5) { @indexer.map_record(MARC::Record.new_from_hash('fields' => url_856_5, 'leader' => leader)) }

    it 'produces many things' do
      expect(result_5['full_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp"}']
      expect(result_5['partial_links_struct']).to match ['{"text":"calldp.leavenworth.army.mil","url":"http://calldp.leavenworth.army.mil/scripts/cqcgi.exe/@ss_prod.env?CQ_SAVE[CGI]=/scripts/cqcgi.exe/@ss_prod.env&CQ_MAIN=YES&CQ_LOGIN=YES&CQDC=Tue%20Jun%2017%202008%2015%3A29%3A03%20GMT-0400%20%28Eastern%20Daylight%20Time%29&CQ_SAVE[GIFs]=/rware/gif8&CQ_USER_NAME=96063898&CQ_PASSWORD=xxx&CQ_SAVE[CPU]=Intel&CQ_SAVE[Browser]=W3C&CQ_SAVE[BrowserVersion]=nav6up&CQ_SAVE[Base]=calldp.leavenworth.army.mil&CQ_SAVE[Home]=http%3A//calldp.leavenworth.army.mil/call_pub.html"}','{"text":"purl.access.gpo.gov","url":"http://purl.access.gpo.gov/GPO/LPS1465"}','{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp"}']
      # expect(result_5['suppl_links_struct']).to be_nil
    end
  end
end
