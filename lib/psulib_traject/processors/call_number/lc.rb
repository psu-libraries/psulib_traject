# frozen_string_literal: true

module PsulibTraject::Processors::CallNumber
  class LC < Base
    attr_reader :call_number,
                :cutter1,
                :cutter2,
                :cutter3,
                :doon1,
                :doon2,
                :doon3,
                :klass,
                :klass_decimal,
                :klass_number,
                :removeables,
                :rest,
                :serial

    def initialize(call_number, serial: false)
      match_data = /
        (?<klass>[A-Z]{0,3})\s*
        (?<klass_number>\d+)?(?<klass_decimal>\.?\d+)?\s*
        (?<doon1>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter1>\.?[a-zA-Z]+\d+([a-zA-Z]+(?![0-9]))?)?\s*
        (?<removeables>(?<doon2>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter2>\.?[a-zA-Z]+\d+([a-zA-Z]+(?![0-9]))?)?\s*
        (?<doon3>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter3>\.?[a-zA-Z]+\d+([a-zA-Z]+(?![0-9]))?)?\s*
        (?<rest>.*))
      /x.match(call_number)

      @call_number = call_number
      match_data ||= {}
      @klass = match_data[:klass] || ''
      @klass_number = match_data[:klass_number]
      @klass_decimal = match_data[:klass_decimal]
      @doon1 = match_data[:doon1]
      @cutter1 = match_data[:cutter1]
      @doon2 = match_data[:doon2]
      @cutter2 = match_data[:cutter2]
      @doon3 = match_data[:doon3]
      @cutter3 = match_data[:cutter3]
      @rest = match_data[:rest]
      @removeables = match_data[:removeables]
      @serial = serial
    end

    def reduce
      value = remove_by_regex
      value = value[0...(value.index(LOOSE_MONTHS_REGEX) || value.length)] # remove loose months

      if serial
        self.class.remove_years(value)
      else
        value.strip
      end
    end

    private

      # @note These are the original regex patterns from Stanford. However, VOL_PATTERN_LOOSER does not currently apply
      # to any of our test data, so it has been commented-out of the procedure.
      def remove_by_regex
        case removeables
        when VOL_PATTERN
          call_number.slice(0...call_number.index(removeables[VOL_PATTERN])).strip
        # when VOL_PATTERN_LOOSER
        #   call_number.slice(0...call_number.index(removeables[VOL_PATTERN_LOOSER])).strip
        when /Blu-ray|DVD/
          bluray_or_dvd
        when VOL_PATTERN_LETTERS
          call_number.slice(0...call_number.index(removeables[VOL_PATTERN_LETTERS])).strip
        when ADDL_VOL_PATTERN
          call_number.slice(0...call_number.index(removeables[ADDL_VOL_PATTERN])).strip
        else
          call_number
        end
      end

      def bluray_or_dvd
        element = removeables[ADDL_VOL_PATTERN]
        return call_number unless element

        call_number.slice(0...call_number.index(removeables[ADDL_VOL_PATTERN])).strip
      end
  end
end
