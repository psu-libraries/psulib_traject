# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Psulib_config spec:' do
  let(:leader) { '1234567890' }
  let(:fixture_path) { './spec/fixtures' }

  describe 'id' do
    context 'one record with trailing whitespace' do
      let(:id) do
        { '001' => '2 ' }
      end
      let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader)) }

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
      let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [id1, id2], 'leader' => leader)) }

      it 'should only take the first match' do
        expect(result['id']).to eq ['2']
      end
    end
  end

  describe 'Call numbers' do
    let(:lc_050) do
      { '050' => { 'ind1' => '0', 'ind2' => '0', 'subfields' => [{ 'a' => 'AC41' },
                                                                 { 'b' => '.A36 1982' }] } }
    end

    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [lc_050], 'leader' => leader)) }

    it 'grouped by single letter with label' do
      expect(result['lc_1letter_facet']).to eq ['A - General Works']
    end

    it 'grouped by all 1-3 letter prefixes with labels' do
      expect(result['lc_rest_facet']).to eq ['AC - Collections Works']
    end
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
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [music_383], 'leader' => leader)) }

    it 'has some semi colons' do
      expect(result[field]).to eq ['op. 36; op. 86; op. 35', 'Bach', 'Motzart']
    end
  end

  describe 'Special collections accessioning numbers' do
    it 'are processed from the 099a' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'special_collections_accessioning_number.mrc')).to_a.first)
      expect(result['scan_sim']).to contain_exactly '09981'
    end
  end

  describe 'Editions' do
    it 'finds cartographic_mathematical_data' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'cartographic.mrc')).to_a.first)
      expect(result['cartographic_mathematical_data_ssm']).to contain_exactly 'Scales differ.'
    end

    it 'finds other edition' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'other_editions.mrc')).to_a.first)
      expect(result['other_edition_ssm']).to contain_exactly '1983-84', '1985'
    end

    it 'finds collection' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'collection.mrc')).to_a.first)
      expect(result['collection_facet']).to contain_exactly 'Arthur O. Lewis Utopia Collection.'
    end
  end

  describe 'HathiTrust access' do
    it 'returns nil when the access field is blank' do
      id = { '001' => '1' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader))

      expect(result['ht_access_ss']).to be_nil
    end

    it 'returns "allow" when duplicates are all mono and the access level is mixed' do
      id = { '001' => '1000065' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader))

      expect(result['ht_access_ss']).to contain_exactly 'allow'
    end

    it 'returns "deny" when duplicates are all multi or serial and the access level is mixed' do
      id = { '001' => '10015944' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader))

      expect(result['ht_access_ss']).to contain_exactly 'deny'
    end

    # This applies for a lot of scenarios. The salient piece is that the records all have a consistent access level
    # whether that's deny or allow
    it 'when there is only one access level present on the record it returns that value' do
      id = { '001' => '10' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader))

      expect(result['ht_access_ss']).to contain_exactly 'deny'
    end

    it 'returns "allow" when duplicates are both mono and multi/serial and the access level is mixed' do
      id = { '001' => '1099502' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => leader))

      expect(result['ht_access_ss']).to contain_exactly 'allow'
    end
  end
end
