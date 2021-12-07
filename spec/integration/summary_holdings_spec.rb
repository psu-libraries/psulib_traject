# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::SummaryHoldings do
  it 'creates a struct of the summary holdings for the record' do
    result = indexer.map_record(MARC::Reader.new(File.join(fixture_path, 'summary_holdings.mrc')).to_a.first)
    holdings = JSON.parse(result['summary_holdings_struct'].first)
    expect(holdings['UP-ANNEX']['CATO-2']).to contain_exactly(
      'call_number' => 'HX1 .M3',
      'summary' => ['v.45(1981)-v.66(2002)'],
      'supplement' => [],
      'index' => []
    )
    expect(holdings['UP-ANNEX']['CATO-PARK']).to contain_exactly(
      'call_number' => 'HX1 .M53',
      'summary' => ['v.36 (Aug.11) 1972-v.44 1980'],
      'supplement' => [],
      'index' => []
    )
    expect(holdings['UP-MICRO']['MFILM-NML']).to contain_exactly(
      'call_number' => 'Microfilm E158',
      'summary' => [
        'v.32 no.1 1968-v.34 no.48 1970 (reel 62:1)',
        'Duplicate filmings: v.33 no.6 1969-v.33 no.9 1969 (reel 38:5), v.33 no.22 1969 (reel 38:5)'
      ],
      'supplement' => [],
      'index' => []
    )
  end
end
