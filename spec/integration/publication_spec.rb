# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Publication' do
  let(:leader) { '1234567890' }

  describe 'Record with a right to left vernacular edition' do
    let(:field) { 'edition_display_ssm' }
    let(:edition_250) do
      { '250' => { 'subfields' => [{ '6' => '880-03' },
                                   { 'a' => 'Chāp-i avval.' }] } }
    end
    let(:edition_vern_250) do
      { '880' => { 'subfields' => [{ '6' => '250-03' },
                                   { 'a' => 'چاپ اول.' }] } }
    end
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [edition_250, edition_vern_250], 'leader' => leader)) }

    it 'has the vernacular edition with a period on the left in the edition statement' do
      expect(result[field]).to eq ['Chāp-i avval.', '.چاپ اول']
      expect(result[field].length).to eq 2
    end

    it 'has empty vern and latin edition field' do
      expect(result).not_to include('edition_vern')
      expect(result).not_to include('edition_latin')
    end
  end

  describe 'Record with a left to right vernacular edition' do
    let(:field) { 'edition_display_ssm' }
    let(:edition_250) do
      { '250' => { 'subfields' => [{ '6' => '880-03' },
                                   { 'a' => 'Tōkyō : Hayakawa Shobō, 1999.' }] } }
    end
    let(:edition_vern_250) do
      { '880' => { 'subfields' => [{ '6' => '250-03' },
                                   { 'a' => '東京 : 早川書房, 1999.' }] } }
    end
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [edition_250, edition_vern_250], 'leader' => leader)) }

    it 'has the vernacular edition with a period on the right in the edition statement' do
      expect(result[field]).to eq ['Tōkyō : Hayakawa Shobō, 1999.', '東京 : 早川書房, 1999.']
      expect(result[field].length).to eq 2
    end

    it 'has empty vern and latin edition field' do
      expect(result).not_to include('edition_vern')
      expect(result).not_to include('edition_latin')
    end
  end

  describe 'Record with no vernacular edition' do
    let(:field) { 'edition_display_ssm' }
    let(:edition_250) do
      { '250' => { 'subfields' => [{ '6' => '880-03' },
                                   { 'a' => 'First Edition.' }] } }
    end
    let(:result) { indexer.map_record(MARC::Record.new_from_hash('fields' => [edition_250], 'leader' => leader)) }

    it 'has the vernacular edition with a period on the right in the edition statement' do
      expect(result[field]).to eq ['First Edition.']
      expect(result[field].length).to eq 1
    end

    it 'has empty vern and latin edition field' do
      expect(result).not_to include('edition_vern')
      expect(result).not_to include('edition_latin')
    end
  end
end
