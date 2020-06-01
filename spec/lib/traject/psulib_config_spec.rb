# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Psulib_config spec:' do
  let(:leader) { '1234567890' }

  before(:all) do
    c = './lib/traject/psulib_config.rb'
    @indexer = Traject::Indexer.new
    @indexer.load_config_file(c)
  end

  describe 'Record with music numeric should have semicolons for all but subfield e' do
    let(:field) { 'music_numerical_ssm' }
    let(:music_383) do
      { '383' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'b' => 'op. 36' },
                                                                 { 'b' => 'op. 86' },
                                                                 { 'b' => 'op. 35' },
                                                                 { 'e' => 'Bach' },
                                                                 { 'e' => 'Motzart' }] } }
    end
    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [music_383], 'leader' => leader)) }

    it 'has some semi colons' do
      expect(result[field]).to eq ['op. 36; op. 86; op. 35', 'Bach', 'Motzart']
    end
  end

  describe 'Call numbers' do
    let(:lc_050) do
      { '050' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'AC41' },
                                                                 { 'b' => '.A36 1982' }] } }
    end

    let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [lc_050], 'leader' => leader)) }

    it 'grouped by single letter with label' do
      expect(result['lc_1letter_facet']).to eq ['A - General Works']
    end

    it 'grouped by all 1-3 letter prefixes with labels' do
      expect(result['lc_rest_facet']).to eq ['AC - Collections Works']
    end
  end

  describe 'id' do
    context 'one record with trailing whitespace' do
      let(:id) do
        { '001' => '2 ' }
      end
      let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader)) }

      it 'should strip off white space at the end' do
        expect(result['id']).to eq ['2']
      end
    end
    context 'one record with two 001 values' do
      let(:id1) do
        { '001' => '2' }
      end
      let(:id2) do
        { '001' => '3' }
      end
      let(:result) { @indexer.map_record(MARC::Record.new_from_hash('fields' => [id1, id2], 'leader' => leader)) }

      it 'should only take the first match' do
        expect(result['id']).to eq ['2']
      end
    end
  end
end
