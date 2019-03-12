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

  describe 'A record with multiple 856s, one with ind2 of 1 and other with ind2 2, neither of which have no-fulltext indicator word in a label subfield' do
    let(:url_856_5) do
      [
        { '856' => { 'ind1' => '0', 'ind2' => '1', 'subfields' => [{ 'u' => 'http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp' }] } },
        { '856' => { 'ind1' => '4', 'ind2' => '2', 'subfields' => [{ 'u' => 'http://calldp.leavenworth.army.mil/' },
                                                                   { 'z' => 'Gateway to archives.' },
                                                                   { 'z' => 'URL does not work, Feb. 3, 2016.' }] } }
      ]
    end
    let(:result_5) { @indexer.map_record(MARC::Record.new_from_hash('fields' => url_856_5, 'leader' => leader)) }

    it 'produces 2 fulltext links and 1 partial link' do
      expect(result_5['full_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp"}',
                                                      '{"text":"calldp.leavenworth.army.mil","url":"http://calldp.leavenworth.army.mil/"}']
      expect(result_5['partial_links_struct']).to match ['{"text":"usacac.army.mil","url":"http://usacac.army.mil/CAC2/MilitaryReview/mrpast2.asp"}']
    end
  end
end
