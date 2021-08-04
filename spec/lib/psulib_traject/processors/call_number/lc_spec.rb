# frozen_string_literal: true

RSpec.describe PsulibTraject::Processors::CallNumber::LC do
  describe '#new' do
    context 'when standard numbers' do
      it 'handles 1 - 3 class letters' do
        expect(described_class.new('P123.23 .M23 2002').klass).to eq 'P'
        expect(described_class.new('PS123.23 .M23 2002').klass).to eq 'PS'
        expect(described_class.new('PSX123.23 .M23 2002').klass).to eq 'PSX'
      end

      it 'parses the class number and decimal' do
        expect(described_class.new('P123.23 .M23 2002').klass_number).to eq '123'
        expect(described_class.new('P123.23 .M23 2002').klass_decimal).to eq '.23'

        expect(described_class.new('P123 .M23 2002').klass_number).to eq '123'
        expect(described_class.new('P123 .M23 2002').klass_decimal).to be_nil
      end

      describe 'doons (dates or other numbers)' do
        it 'parses a doon after the class number/decimal and before the 1st cutter' do
          expect(described_class.new('P123.23 2012 .M23 2002 .M45 V.1').doon1).to match(/^2012/)
        end

        it 'parses a doon after the 1st cutter and before other cutters' do
          expect(described_class.new('P123.23 2012 .M23 2002 .M45 V.1').doon2).to match(/^2002/)
        end

        it 'parses a doon after the 2nd cutter and before other cutters' do
          expect(described_class.new('G4362 .L3 .E63 1997 .E2').doon3).to match(/^1997/)
        end

        it 'allows for characters after the number in the doon (e.g. 12TH)' do
          expect(described_class.new('P123.23 20TH .M45 V.1').doon1).to match(/^20TH/)
        end
      end

      describe 'cutters' do
        it 'handles 3 possible cutters' do
          expect(described_class.new('P123.23 .M23 V.1 2002').cutter1).to eq '.M23'
          expect(described_class.new('P123.23 .M23 V.1 2002').cutter2).to be_nil
          expect(described_class.new('P123.23 .M23 V.1 2002').cutter3).to be_nil

          expect(described_class.new('P123.23 .M23 .M45 V.1 2002').cutter1).to eq '.M23'
          expect(described_class.new('P123.23 .M23 .M45 V.1 2002').cutter2).to eq '.M45'
          expect(described_class.new('P123.23 .M23 .M45 V.1 2002').cutter3).to be_nil

          expect(described_class.new('P123.23 .M23 .M45 .S32 V.1 2002').cutter1).to eq '.M23'
          expect(described_class.new('P123.23 .M23 .M45 .S32 V.1 2002').cutter2).to eq '.M45'
          expect(described_class.new('P123.23 .M23 .M45 .S32 V.1 2002').cutter3).to eq '.S32'
        end

        it 'handles multi-letter cutters' do
          expect(described_class.new('P123.23 .MS23').cutter1).to eq '.MS23'
          expect(described_class.new('P123.23 .MSA23').cutter1).to eq '.MSA23'
        end

        it 'handles a single letter after the cutter number' do
          expect(described_class.new('P123.23 .MS23A').cutter1).to eq '.MS23A'
        end

        it 'parses cutters that do not have a space before them' do
          expect(described_class.new('P123.23.M23.S32').cutter1).to eq '.M23'
          expect(described_class.new('P123.23.M23.S32').cutter2).to eq '.S32'
        end

        it 'parses cutters with no space or period' do
          expect(described_class.new('P123M23S').cutter1).to eq 'M23S'
          expect(described_class.new('P123M23SL').cutter1).to eq 'M23SL'
          expect(described_class.new('P123M23S32').cutter1).to eq 'M23'
          expect(described_class.new('P123M23S32').cutter2).to eq 'S32'
        end
      end
    end

    describe 'the rest of the stuff' do
      it 'puts any other content into the rest attribute' do
        expect(described_class.new('P123.23 .M23 V.1 2002').rest).to eq 'V.1 2002'
        expect(described_class.new('P123.23 2012 .M23 2002 .M45 V.1 2002-2012/GobbldyGoop').rest)
          .to eq 'V.1 2002-2012/GobbldyGoop'
      end
    end
  end

  describe '#reduce' do
    RSpec::Matchers.define :reduce_to do |expected|
      match do |actual|
        described_class.new(actual).reduce == expected
      end
      failure_message do |actual|
        "expected #{actual} to reduce to #{expected} but got #{described_class.new(actual).reduce} instead."
      end
    end

    RSpec::Matchers.define :serial_reduce_to do |expected|
      match do |actual|
        described_class.new(actual, serial: true).reduce == expected
      end
      failure_message do |actual|
        "expected #{actual} to reduce to #{expected} but got #{described_class.new(actual).reduce} instead."
      end
    end

    context 'when non-serial' do
      it 'leaves cutters intact' do
        expect('P123.23 .M23 A12').to reduce_to('P123.23 .M23 A12')
      end

      it 'drops data after the first volume designation' do
        expect('PN2007 .S589 NO.17 1998').to reduce_to('PN2007 .S589')
        expect('PN2007 .K3 V.7:NO.4').to reduce_to('PN2007 .K3')
        expect('PN2007 .K3 V.8:NO.1-2 1972').to reduce_to('PN2007 .K3')
        expect('PN2007 .K3 V.5-6:NO.11-25 1967-1970').to reduce_to('PN2007 .K3')
        expect('PN2007 .S3 NO.14-15,34').to reduce_to('PN2007 .S3')
        expect('PJ5008.Z55G47 1959 k.6').to reduce_to('PJ5008.Z55G47 1959')
        expect('PJ5008.Z55G47 1959 h.6').to reduce_to('PJ5008.Z55G47 1959')
        expect('BM520.88.A52I87 1952 ḥ.1').to reduce_to('BM520.88.A52I87 1952')
        expect('DS118.R587 1927 Tl.1').to reduce_to('DS118.R587 1927')
      end

      it 'retains a year right after the cutter' do
        expect('PN2007 .S3 1987').to reduce_to('PN2007 .S3 1987')
        expect('PN2007 .K93 2002/2003:NO.3/1').to reduce_to('PN2007 .K93 2002/2003')
        expect('PN2007 .Z37 1993:JAN.-DEC').to reduce_to('PN2007 .Z37 1993')
        expect('PN2007 .Z37 1994:SEP-1995:JUN').to reduce_to('PN2007 .Z37 1994')
        expect('PN2007 .K93 2002:NO.1-2').to reduce_to('PN2007 .K93 2002')
      end

      it 'handles multiple cutters' do
        expect('PN1993.5 .A35 A373 VOL.4').to reduce_to('PN1993.5 .A35 A373')
        expect('PN1993.5 .A1 S5595 V.2 2008').to reduce_to('PN1993.5 .A1 S5595')
        expect('PN1993.5 .A75 C564 V.1:NO.1-4 2005').to reduce_to('PN1993.5 .A75 C564')
        expect('PN1993.5 .L3 S78 V.1-2 2004-2005').to reduce_to('PN1993.5 .L3 S78')

        # When the year is first
        expect('PN1993.5 .F7 A3 2006:NO.297-300').to reduce_to('PN1993.5 .F7 A3 2006')
        expect('JQ1519 .A5 A369 1990:NO.1-9+SUPPL.').to reduce_to('JQ1519 .A5 A369 1990')
        expect('PN1993.5 .F7 A3 2005-2006 SUPPL.NO.27-30').to reduce_to('PN1993.5 .F7 A3 2005-2006 SUPPL')
        expect('PN1993.5 .S6 S374 F 2001:JUL.-NOV.').to reduce_to('PN1993.5 .S6 S374 F 2001')
      end

      it 'does not remove an existing ellipsis' do
        expect('A1 .B2 ...').to reduce_to('A1 .B2 ...')
        expect('A1 .B2 BOO ...').to reduce_to('A1 .B2 BOO ...')
        expect('A1 .B2 BOO .C3 BOO ...').to reduce_to('A1 .B2 BOO .C3 BOO ...')
      end

      it 'handles edition data, number followed by (st|nd|rd|th|d)' do
        expect('TK7872.O7S901 31st 1996/60').to reduce_to('TK7872.O7S901')
        expect('TK7872.O7S901 22nd 1996').to reduce_to('TK7872.O7S901')
        expect('TK7872.O7S901 3rd 1996').to reduce_to('TK7872.O7S901')
        expect('TK7872.O7S901 122d 1996').to reduce_to('TK7872.O7S901')
        expect('TK7872.O7S901 50th 1996').to reduce_to('TK7872.O7S901')
      end
    end

    context 'when a serial' do
      it 'leaves cutters intact' do
        expect('P123.23 .M23 A12').to serial_reduce_to('P123.23 .M23 A12')
      end

      it 'drops data after the first volume designation' do
        expect('PN2007 .S589 NO.17 1998').to serial_reduce_to('PN2007 .S589')
        expect('PN2007 .K3 V.7:NO.4').to serial_reduce_to('PN2007 .K3')
        expect('PN2007 .K3 V.8:NO.1-2 1972').to serial_reduce_to('PN2007 .K3')
        expect('PN2007 .K3 V.5-6:NO.11-25 1967-1970').to serial_reduce_to('PN2007 .K3')
        expect('PN2007 .S3 NO.14-15,34').to serial_reduce_to('PN2007 .S3')
      end

      it 'drops year data after the cutter' do
        expect('PN2007 .S3 1987').to serial_reduce_to('PN2007 .S3')
        expect('PN2007 .K93 2002/2003:NO.3/1').to serial_reduce_to('PN2007 .K93')
        expect('PN2007 .Z37 1993:JAN.-DEC').to serial_reduce_to('PN2007 .Z37')
        expect('PN2007 .Z37 1994:SEP-1995:JUN').to serial_reduce_to('PN2007 .Z37')
        expect('PN2007 .K93 2002:NO.1-2').to serial_reduce_to('PN2007 .K93')
      end

      it 'drops date ranges with "index|ind' do
        expect('HQ1101.M72 Index Spr.1972-Feb.1974').to serial_reduce_to('HQ1101.M72')
      end
    end

    context 'with DVDs and Blu-ray discs' do
      it 'retains Blu-ray' do
        expect('PN1997.2.L66255 2017 Blu-ray').to reduce_to('PN1997.2.L66255 2017 Blu-ray')
      end

      it 'retains DVD' do
        expect('PN1997.2.L66255 2017 DVD').to reduce_to('PN1997.2.L66255 2017 DVD')
      end

      it 'retains Blu-ray/DVD' do
        expect('PN1997.2.L66255 2017 Blu-ray/DVD').to reduce_to('PN1997.2.L66255 2017 Blu-ray/DVD')
        expect('PN1997.2.V5454 2017 Blu-ray/DVD').to reduce_to('PN1997.2.V5454 2017 Blu-ray/DVD')
      end

      it 'drops the Blu-ray volume' do
        expect('PN1997.A1M216 2014 Blu-ray v.1').to reduce_to('PN1997.A1M216 2014 Blu-ray')
      end

      it 'drops the Blu-ray disc number' do
        expect('PN1995.9.J34Z38 2014 Blu-ray disc.4').to reduce_to('PN1995.9.J34Z38 2014 Blu-ray')
      end

      it 'drops the DVD booklet' do
        expect('PN1997.A1M216 2014 DVD bklet.').to reduce_to('PN1997.A1M216 2014 DVD')
      end

      it 'drops the DVD disc number' do
        expect('PN1997.A1M216 2014 DVD v.1 disc.1').to reduce_to('PN1997.A1M216 2014 DVD')
        expect('PN1995.9.J34Z38 2014 DVD disc.4').to reduce_to('PN1995.9.J34Z38 2014 DVD')
      end
    end

    context 'with microformats' do
      it 'removes Microfiche' do
        expect('AP2.A8 Microfiche').to serial_reduce_to('AP2.A8')
        expect('AP2.A8 Microfiche').to reduce_to('AP2.A8')
      end
    end

    context 'when the cutter letter is the same as a volume designation' do
      it 'preserves the H' do
        expect('QA76.9.D3H365153 2000').to reduce_to('QA76.9.D3H365153 2000')
      end

      it 'preserves the K' do
        expect('PJ5129.A8K65 1921 Bd.11').to reduce_to('PJ5129.A8K65 1921')
      end
    end
  end
end
