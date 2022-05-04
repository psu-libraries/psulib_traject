# frozen_string_literal: true

module PsulibTraject::Processors::CallNumber
  class Base
    MONTHS = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|spr|spring|sum|summer|fall|win|winter'

    ORDINALS = '\d{1,3}(st|nd|rd|th|d)'

    VOL_PARTS = %w(
      bd
      disc
      ed
      hov
      iss
      issue
      (\d+)?-?(\d+)?.?jahrg
      microfiche
      new ser
      part
      pts?
      ser
      shanah
      tbd
      vols?
      vyp
    ).join('|')

    ADDL_VOL_PARTS = %w(
      anné
      a(n|ñ)o
      bklet
      box
      carton
      cass
      cis
      dil
      (\d+)?a?( |.)(e|é)poca
      fig
      flat box
      grade
      half box
      half carton
      Hft
      index
      kn
      knj
      large folder
      large map folder
      leto
      lp
      map folder
      maps
      mfiche
      mfilm
      Nr
      os box
      os folder
      page
      panel
      pl
      rel
      reel
      rik
      roc
      series
      ses
      sheet
      slides
      small folder
      small map folder
      suppl
      svar
      special
      text
      tl
      tube
    ).freeze

    # Place patterns here that might interfere with other patterns (ex. 'e.' could interfere with 'page')
    LAST_TO_CUT = "[^a-z]t|v\\.|no|k\\.|h\\.|ḥ\\.|t\\.|e\\.|g\\.|n\\.|#{ORDINALS}"

    ADDL_VOL_PATTERN = /[:\/]?(#{ADDL_VOL_PARTS.join('|')}).*/i.freeze
    VOL_PARTS_ALL = "((index|ind)\s)?(#{VOL_PARTS}|#{MONTHS})"
    LAST_TO_CUT_ALL = "((index|ind)\s)?(#{LAST_TO_CUT})"
    VOL_PATTERN         = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{VOL_PARTS_ALL}[. \-\/]?(\d+)?([\/-]\d+)?( \d{4}([\/-]\d{4})?)?( ?suppl\.?)?/i.freeze
    VOL_PATTERN_LOOSER  = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{VOL_PARTS_ALL}[. -]?\d+.*/i.freeze
    LAST_TO_CUT_PATTERN = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{LAST_TO_CUT_ALL}[\/. -]?[A-Z]?([\/-][A-Z]+)?(\d+)?.*/i.freeze
    FOUR_DIGIT_YEAR_REGEX = /\W *(20|19|18|17|16|15|14)\d{2}\D?$?/.freeze
    LOOSE_MONTHS_REGEX = /([.:\/(])? *#{MONTHS}/i.freeze

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

    class << self
      def remove_years(value)
        month_b4_year = value[0...(value.index(LOOSE_MONTHS_REGEX) || value.length)]
        year_b4_month = value[0...(value.index(FOUR_DIGIT_YEAR_REGEX) || value.length)]
        shortest_value = [month_b4_year, year_b4_month].min_by(&:length)
        return value if shortest_value.length < 4

        shortest_value
      end
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

      def remove_by_regex
        case removeables
        when VOL_PATTERN
          call_number.slice(0...call_number.index(removeables[VOL_PATTERN])).strip
        when ADDL_VOL_PATTERN
          call_number.slice(0...call_number.index(removeables[ADDL_VOL_PATTERN])).strip
        when LAST_TO_CUT_PATTERN
          call_number.slice(0...call_number.index(removeables[LAST_TO_CUT_PATTERN])).strip
        else
          call_number
        end
      end
  end
end
