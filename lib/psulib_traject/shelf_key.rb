# frozen_string_literal: true

module PsulibTraject
  class ShelfKey
    FORWARD_CHARS = ('0'..'9').to_a + ('A'..'Z').to_a
    CHAR_MAP = FORWARD_CHARS.zip(FORWARD_CHARS.reverse).to_h

    class NullKey < NullObject; end

    attr_reader :call_number

    # @param [String] call_number
    def initialize(call_number, prefix: '')
      @call_number = prefix + call_number
      freeze
    end

    # @return [String]
    def forward
      Shelvit.normalize(call_number) || NullKey.new
    end

    # @return [String]
    def reverse
      forward
        .chars
        .map { |char| CHAR_MAP.fetch(char, char) }
        .append('~')
        .join
    end
  end
end
