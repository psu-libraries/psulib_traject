# frozen_string_literal: true

module PsulibTraject
  class ShelfKey

    class NullKey < NullObject; end

    attr_reader :call_number

    # @param [String] call_number
    def initialize(call_number, prefix: '')
      @call_number = prefix + call_number
      freeze
    end

    # @return [String]
    def normalized
      Shelvit.normalize(call_number) || NullKey.new
    end
  end
end
