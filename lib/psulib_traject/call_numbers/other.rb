# frozen_string_literal: true

module PsulibTraject::CallNumbers
  class Other < CallNumberBase
    attr_reader :call_number, :serial

    def initialize(call_number, serial: false)
      @call_number = call_number
      @serial = serial
    end

    def lopped; end
  end
end
