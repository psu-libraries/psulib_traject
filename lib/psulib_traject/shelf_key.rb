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
      # we want to make sure we sort after Z if there is a colon
      processed_call_number = call_number.gsub(':', 'ZZ')
      Shelvit.normalize(processed_call_number) || NullKey.new
    end
  end
end
