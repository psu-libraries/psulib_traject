# frozen_string_literal: true

module PsulibTraject::CallNumbers
  class CallNumberBase
    MONTHS = 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|spr|spring|sum|summer|fall|win|winter'
    ORDINALS = '\d{1,3}(st|nd|rd|th|d)'
    VOL_PARTS = "bd|tbd|ed|hov|iss|issue|jahrg|new ser|no|part|pts?|ser|shanah|[^a-z]t|v|vols?|vyp|k|h|#{ORDINALS}"
    ADDL_VOL_PARTS = [
      'bklet', 'box', 'carton', 'cass', 'fig', 'flat box', 'grade', 'half box',
      'half carton', 'index', 'large folder', 'large map folder', 'lp', 'maps',
      'map folder', 'mfilm', 'mfiche', 'os box', 'os folder', 'pl', 'reel',  'series',
      'sheet', 'slides', 'small folder', 'small map folder', 'suppl', 'text', 'tube'
    ].freeze
    ADDL_VOL_PATTERN = /[:\/]?(#{ADDL_VOL_PARTS.join('|')}).*/i.freeze
    VOL_PARTS_ALL = "((index|ind)\s)?(#{VOL_PARTS}|#{MONTHS})"
    VOL_PATTERN         = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{VOL_PARTS_ALL}[. -\/]?\d+([\/-]\d+)?( \d{4}([\/-]\d{4})?)?( ?suppl\.?)?/i.freeze
    VOL_PATTERN_LOOSER  = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{VOL_PARTS_ALL}[. -]?\d+.*/i.freeze
    VOL_PATTERN_LETTERS = /([.:\/(])?(n\.s\.?,? ?)?[:\/]?#{VOL_PARTS_ALL}[\/. -]?[A-Z]?([\/-][A-Z]+)?.*/i.freeze
    FOUR_DIGIT_YEAR_REGEX = /\W *(20|19|18|17|16|15|14)\d{2}\D?$?/.freeze
    LOOSE_MONTHS_REGEX = /([.:\/(])? *#{MONTHS}/i.freeze

    def lopped
      raise NotImplementedError
    end

    class << self
      def lop_years(value)
        month_b4_year = value[0...(value.index(LOOSE_MONTHS_REGEX) || value.length)]
        year_b4_month = value[0...(value.index(FOUR_DIGIT_YEAR_REGEX) || value.length)]
        shortest_lopped = [month_b4_year, year_b4_month].min_by(&:length)
        return value if shortest_lopped.length < 4

        shortest_lopped
      end
    end
  end
end