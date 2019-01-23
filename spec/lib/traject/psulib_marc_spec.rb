# frozen_string_literal: true

require_relative '../../../lib/traject/psulib_marc'

RSpec.describe 'From psulib_marc.rb' do
  describe 'process_hierarchy function' do
    before(:all) do
      @s610 = { '600' => { 'ind1' => '', 'ind2' => '5', 'subfields' => [{ 'a' => 'Exclude' }] } }
      @s600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 't' => 'Title.' }, { 'v' => 'split genre' }, { 'd' => '2015' }, { '2' => 'special' }] } }
      @s630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'z' => "don't ignore" }, { 't' => 'TITLE.' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@s610, @s600, @s630])
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

  describe 'process_subject_topic_facet function' do
    before(:all) do
      @s600 = { '600' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'a' => 'John.' }, { 'x' => 'Join' }, { 't' => 'Title' }, { 'd' => '2015' }] } }
      @s630 = { '630' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'x' => 'Fiction' }, { 'y' => '1492' }, { 'z' => "don't ignore" }, { 'v' => 'split genre' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@s600, @s630])
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

  describe 'process_genres function' do
    before(:all) do
      @g650 = { '650' => { 'ind1' => '', 'ind2' => '0', 'subfields' => [{ 'v' => 'Maps' }, { 'z' => 'Tippah County' }] } }
      @g655_fast = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Fiction films' }, { 'b' => '1900' }, { '2' => "fast" }, { 'z' => 'Germany' }] } }
      @g655_lcgft = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Drama.' }, { '2' => 'lcgft' }] } }
      @g655_aat = { '655' => { 'ind1' => '', 'ind2' => '7', 'subfields' => [{ 'a' => 'Novels' }, { '2' => 'aat' }] } }
      @sample_marc = MARC::Record.new_from_hash('fields' => [@g650, @g655_fast, @g655_lcgft, @g655_aat])
      @genres = process_genre(@sample_marc, '655|*0|abcvxyz:655|*7|abcvxyz')
    end

    it 'trims punctuation' do
      expect(@genres).to include('Drama')
    end

    it 'limits 655 to fast and lcgft genres' do
      expect(@genres).to include('Fiction films 1900 Germany')
      expect(@genres).to include('Drama')
    end
  end
end
