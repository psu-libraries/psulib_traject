# frozen_string_literal: true

module PsulibTraject
  class ShelfKey
    FORWARD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a
    CHAR_MAP = FORWARD_CHARS.zip(FORWARD_CHARS.reverse).to_h

    # Map lower-case letters to numbers for cutter sorting
    LOWER_MAP = ('a'..'z').to_a.zip(('00'..'26').to_a).to_h

    class NullKey < NullObject; end

    attr_reader :call_number

    # @param [String] call_number
    def initialize(call_number)
      @call_number = call_number
      freeze
    end

    # @return [String]
    def forward
      Lcsort.normalize(call_number) || normalize
    end

    # @return [String]
    def reverse
      forward
        .chars
        .map { |char| CHAR_MAP.fetch(char, char) }
        .append('~')
        .join
    end

    private

      def normalize
        Lcsort.normalize(cleaned) || NullKey.new
      end

      # @note If Lcsort can't properly normalize the call number, we "clean" it up by translating unsortable characters
      # into sortable ones:
      #
      # 1. Lower-case letters are translated into numbers 00 through 25. Ex. PZ7.H56774Fz becomes PZ7.H56774F25
      # 2. Colons are replaced with periods
      # 3. LC numbers that have no number after their letter classification have a '0' added. Ex, KKP.B634 becomes
      #    KKP0.B634
      #
      # Note that this only affects the _key_. The original call number is unchanged.
      def cleaned
        call_number
          .gsub(/([a-z])/, LOWER_MAP)
          .gsub(/:/, '.')
          .gsub(/(^[A-Z]{1,3})\.([A-Z])/, '\10.\2')
      end
  end
end
