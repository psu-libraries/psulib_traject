# frozen_string_literal: true

RSpec.describe 'Subjects' do
  describe 'process_subject_hierarchy' do
    before(:all) do
      @subject610 = { '610' => { 'ind1' => '', 'ind2' => '5', 'subfields' => [{ 'a' => 'Include' }] } }
      @subject600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 't' => 'Title.' }, { 'v' => 'split genre' }, { 'd' => '2015' }, { '2' => 'special' }] } }
      @subject630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'z' => "don't ignore" }, { 't' => 'TITLE.' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@subject610, @subject600, @subject630], 'leader' => '1234567890')
    end

    it 'only separates v,x,y,z with em dash, strips punctuation' do
      result = indexer.map_record(@sample_marc)
      expect(result['subject_display_ssm']).to include('Include')
      expect(result['subject_display_ssm']).to include("John. Title#{SEPARATOR}split genre 2015")
      expect(result['subject_display_ssm']).to include("Fiction#{SEPARATOR}1492#{SEPARATOR}don't ignore TITLE")
    end
  end

  describe 'process_subject_topic_facet' do
    before(:all) do
      @subject600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 'x' => 'Join' }, { 't' => 'Title' }, { 'd' => '2015.' }] } }
      @subject650 = { '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'v' => 'split genre' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@subject600, @subject650], 'leader' => '1234567890')
    end

    it 'includes subjects split along v, x, y and z, strips punctuation' do
      result = indexer.map_record(@sample_marc)
      expect(result['subject_topic_facet']).to include('John. Title 2015')
      expect(result['subject_topic_facet']).to include('Fiction')
    end
  end
end
