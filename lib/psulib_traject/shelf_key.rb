# frozen_string_literal: true

module PsulibTraject
  class ShelfKey
    class NullKey < NullObject; end

    attr_reader :call_number

    # @param [String] call_number
    def initialize(call_number, prefix: '')
      @call_number = prefix + call_number
      @has_colon = call_number.include?(':')
      freeze
    end

    # @return [String]
    def normalized
      normalized_call_number = Shelvit.normalize(call_number) || NullKey.new

      if @has_colon
        '~' + normalized_call_number
      else
        normalized_call_number
      end
    end
  end
end
