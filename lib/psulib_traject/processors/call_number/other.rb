# frozen_string_literal: true

module PsulibTraject::Processors::CallNumber
  class Other < Base
    attr_reader :call_number, :serial

    def initialize(call_number, serial: false)
      @call_number = call_number
      @serial = serial
    end

    def reduce
      call_number
    end
  end
end
