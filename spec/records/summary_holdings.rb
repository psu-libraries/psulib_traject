# frozen_string_literal: true

MarcBot.define do
  factory :single_summary_holdings do
    f852 do
      { b: 'UP-SPECCOL', c: 'HC-SERIALS', h: 'HD6515.P4 I5 F' }
    end
    f866 { 'v.12(1956/57)-v.40:1-7/8(1984)' }
    f867 { 'Supplemental' }
    f868 { 'Index' }
  end

  factory :multiple_summary_holdings do
    f852 do
      { b: 'UP-ANNEX', c: 'CATO-2', h: 'HX1 .M3' }
    end
    f852 do
      { b: 'UP-SPECCOL', c: 'HC-SERIALS', h: 'HD6515.P4 I5 F' }
    end
    f866 { 'v.12(1956/57)-v.40:1-7/8(1984)' }
    f867 { 'Supplemental' }
    f868 { 'Index' }
    f852 do
      { b: 'UP-ANNEX', c: 'CATO-3', h: 'AC1 .X98' }
    end
    f852 do
      { b: 'UP-ANNEX', c: 'CATO-3', h: 'AC1 .X99' }
    end
    f866 { 'v.1(2000)- to Date.' }
  end

  factory :sample_summary_holdings do
    f852 do
      { b: 'Library', c: 'Location', h: 'Call Number' }
    end

    f866 do
      { a: 'the first summary', z: 'extra summary 1' }
    end
    f866 do
      { a: 'the second summary', z: 'extra summary 2' }
    end
    f867 do
      { a: 'the first supplement', z: 'extra supplement 1' }
    end
    f867 do
      { a: 'the second supplement', z: 'extra supplement 2' }
    end
    f868 do
      { a: 'the first index', z: 'extra index 1' }
    end
    f868 do
      { a: 'the second index', z: 'extra index 2' }
    end
  end
end
