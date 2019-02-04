# frozen_string_literal: true

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.describe 'Audience spec:' do
  let(:leader) { '1234567890' }
  let(:audience_qual) do
    { '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
        { 'm' => 'Age' },
        { 'a' => 'Children' },
        { '2' => 'lcdgt' }] },
      '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
          { 'm' => 'Age' },
          { 'a' => 'Children' },
          { '2' => 'lcdgt' }] },
      '385' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [
          { 'm' => 'Age' },
          { 'a' => 'Children' },
          { '2' => 'lcdgt' }] }
    }
  end
  let(:audience_qual_marc) do
    @indexer.map_record(MARC::Record.new_from_hash('fields' => [audience_qual],
                                                   'leader' => leader))
  end
  # 385 m| Age a| Children 2| lcdgt
  # 385 m| Educational level a| School children 2| lcdgt
  # 385 m| Educational level a| Kindergarteners 2| lcdgt


  before(:all) do

  end

  descirbe 'Record with qualifying audience data' do

  end


end