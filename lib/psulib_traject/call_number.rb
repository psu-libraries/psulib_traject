# frozen_string_literal: true

module PsulibTraject
  class CallNumber
    SERIAL_ITEM_TYPES = %w(SERIAL PERIODSPEC PERIODICAL BNDSER-DSL BNDSER-HY).freeze

    attr_reader :value, :classification, :location, :item_type, :leader

    def initialize(value:, classification:, location:, item_type:, leader:)
      @value = value
      @classification = classification
      @location = location
      @item_type = item_type
      @leader = leader
    end

    def lop
      @value = lopped_value
    end

    def serial?
      SERIAL_ITEM_TYPES.include?(item_type) ||
        item_type == 'MICROFORM' && %w(ab as).include?(leader[6..7])
    end

    private

      def lopped_value
        case classification
        when 'LC', 'LCPER'
          PsulibTraject::CallNumbers::LC.new(value, serial: serial?).lopped
        when 'DEWEY'
          PsulibTraject::CallNumbers::Dewey.new(value).lopped
        else
          PsulibTraject::CallNumbers::Other.new(value).lopped
        end
      end
  end
end
