# frozen_string_literal: true

module PsulibTraject
  class ShelfKey
    FORWARD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a
    CHAR_MAP = FORWARD_CHARS.zip(FORWARD_CHARS.reverse).to_h

    attr_reader :call_number

    # @param [String] call_number
    def initialize(call_number)
      @call_number = call_number
      freeze
    end

    # @return [String]
    def forward
      Lcsort.normalize(call_number) || default_forward_key
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

      def default_forward_key
        call_number.upcase.gsub(/ /, '.')
      end
  end
end
