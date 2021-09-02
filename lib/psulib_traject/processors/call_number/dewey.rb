# frozen_string_literal: true

module PsulibTraject::Processors::CallNumber
  class Dewey < Base
    def initialize(call_number, serial: false)
      match_data = /
        (?<klass_number>\d{1,3})(?<klass_decimal>\.?\d+)?\s*
        (?<doon1>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter1>[.\/]?[a-zA-Z]+\d+([a-zA-Z]*(?![0-9])))?\s*
        (?<removeables>(?<doon2>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter2>[.\/]?[a-zA-Z]+\d+([a-zA-Z]*(?![0-9])))?\s*
        (?<doon3>(\d{1,4})(?:ST|ND|RD|TH|D)?\s+)?\s*
        (?<cutter3>[.\/]?[a-zA-Z]+\d+([a-zA-Z]*(?![0-9])))?\s*
        (?<rest>.*))
      /x.match(call_number)

      @call_number = call_number
      match_data ||= {}
      @klass_number = match_data[:klass_number]
      @klass_decimal = match_data[:klass_decimal]
      @doon1 = match_data[:doon1]
      @cutter1 = match_data[:cutter1]
      @doon2 = match_data[:doon2]
      @doon3 = match_data[:doon3]
      @cutter2 = match_data[:cutter2]
      @cutter3 = match_data[:cutter3]
      @rest = match_data[:rest]
      @removeables = match_data[:removeables]
      @serial = serial
    end
  end
end
