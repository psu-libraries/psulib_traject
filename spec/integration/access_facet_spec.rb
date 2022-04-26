# frozen_string_literal: true

RSpec.describe 'Access facet' do
  describe 'access_facet' do
    it 'works with empty record, returns empty' do
      @empty_record = MARC::Record.new
      @empty_record.append(MARC::ControlField.new('001', '000000000'))
      result = indexer.map_record(@empty_record)
      expect(result['access_facet']).to be_nil
    end

    it 'produces In the Library and Online when a record has both an online copy and a physical copy' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_in_library.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'In the Library', 'Online'
    end

    it 'produces On Order when a record has a copy with an on-order location' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_on_order.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'On Order'
    end

    it 'produces In the Library and Online when a record has an online copy, a physical copy and an on-order copy' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_all.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'In the Library', 'Online'
    end

    it 'produces a uniq set of access facet values' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_uniq.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'Online', 'In the Library'
    end

    it 'produces Other when a record has a 949m library code that is not listed' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_other.mrc')).to_a.first)
      expect(result['access_facet']).to contain_exactly 'Other'
    end

    it 'empty when a record has a 949m library code ZREMOVED, XTERNAL or UP-OFFICE' do
      result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_zremoved.mrc')).to_a.first)
      expect(result['access_facet']).to be_nil
    end

    context 'when a record has a copy that appears to be "open access' do
      it 'produces "Free to Read" when record has one 506' do
        result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_open_access.mrc')).to_a.first)
        expect(result['access_facet']).to contain_exactly 'Online', 'Free to Read'
      end

      it 'produces "Free to Read" when record has multiple 506s' do
        result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'access_open_access_multi_506.mrc')).to_a.first)
        expect(result['access_facet']).to contain_exactly 'Online', 'Free to Read'
      end
    end

    it 'produces Online when a record has a HathiTrust copy with only "allow" permissions' do
      id = { '001' => '1000103' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

      expect(result['access_facet']).to contain_exactly 'Online'
    end

    it 'produces Online when a record has a HathiTrust copy with "deny" and "allow" permissions' do
      id = { '001' => '1000065' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

      expect(result['access_facet']).to contain_exactly 'Online'
    end

    it 'skips when a record has a HathiTrust copy with "deny" permissions' do
      id = { '001' => '10' }
      result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

      expect(result['access_facet']).to be_nil
    end

    context 'in the time of HathiTrust Emergency Temporary Access Service (ETAS)' do
      before do
        ConfigSettings.hathi_etas = true
      end

      it 'produces Online when a record has a HathiTrust copy with only "allow" permissions' do
        id = { '001' => '1000103' }
        result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

        expect(result['access_facet']).to contain_exactly 'Online'
      end

      it 'produces Online when a record has a HathiTrust copy with "deny" and "allow" permissions' do
        id = { '001' => '1000065' }
        result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

        expect(result['access_facet']).to contain_exactly 'Online'
      end

      it 'produces Online when a record has a HathiTrust copy with "deny" permissions' do
        id = { '001' => '10' }
        result = indexer.map_record(MARC::Record.new_from_hash('fields' => [id], 'leader' => '1234567890'))

        expect(result['access_facet']).to contain_exactly 'Online'
      end
    end
  end
end
