# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Audience spec:' do
  let(:leader) { '1234567890' }
  let(:audience_qual1) do
    { '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
      { 'm' => 'Age' },
      { 'a' => 'Children' },
      { '2' => 'lcdgt' }
    ] } }
  end
  let(:audience_qual2) do
    { '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
      { 'm' => 'Age' },
      { 'a' => 'School children' },
      { '2' => 'lcdgt' }
    ] } }
  end
  let(:audience_qual3) do
    { '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
      { 'm' => 'Age' },
      { 'a' => 'Kindergarteners' },
      { '2' => 'lcdgt' }
    ] } }
  end
  let(:audience_qual_marc) do
    indexer.map_record(MARC::Record.new_from_hash('fields' => [audience_qual1, audience_qual2, audience_qual3],
                                                  'leader' => leader))
  end

  describe 'Record with qualifying audience data' do
    it 'has a multiple 385s with "m" subfield as "designator"' do
      expect(audience_qual_marc['audience_ssm']).to include 'Age: School children'
    end
  end
end
