# frozen_string_literal: true

RSpec.describe 'Bound with spec:' do
  let(:leader) { '1234567890' }

  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'Child items bound in' do
    let(:bound_with_catkey) { { '591' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
                              { 'a' => 'The high-caste Hindu woman / With introduction by Rachel L. Bodley' },
                              { 'c' => '355035' }] } } }
    let(:bound_with_multi) { { '591' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
                             { 'a' => 'blah blah blah' }] } } }
    let(:bound_with_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [bound_with_catkey],
                                                                           'leader' => leader)) }
    let(:bound_with_multi_marc) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [bound_with_catkey, bound_with_multi], 'leader' => leader)) }

    it 'shows the parent title' do
      expect(bound_with_marc['bound_with_title_struct']).to match ['{"boundcatkey": "355035", "boundtitle": "The high-caste Hindu woman / With introduction by Rachel L. Bodley"}']
    end
    it 'shows the binding notes when there are more than one 591' do
      expect(bound_with_multi_marc['bound_with_notes_ssm']).to include 'blah blah blah'
    end
  end
end
