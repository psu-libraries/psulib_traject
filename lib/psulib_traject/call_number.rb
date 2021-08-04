# frozen_string_literal: true

module PsulibTraject
  class CallNumber
    SERIAL_ITEM_TYPES = %w(
      SERIAL
      PERIODSPEC
      PERIODICAL
      BNDSER-DSL
      BNDSER-HY
    ).freeze

    attr_reader :value, :classification, :location, :item_type, :leader

    def initialize(value: '', classification: '', location: '', item_type: '', leader: '')
      @value = value
      @classification = classification
      @location = location
      @item_type = item_type
      @leader = leader
    end

    def reduce!
      @value = base_value
    end

    def forward_shelfkey
      shelf_key.forward
    end

    def reverse_shelfkey
      shelf_key.reverse
    end

    def keymap
      {
        forward_shelfkey => value,
        reverse_shelfkey => value
      }
    end

    def periodical?
      value == 'Periodical'
    end

    def newspaper?
      value == 'Newspaper'
    end

    def local?
      value.start_with?('xx(')
    end

    def on_order?
      location == 'ON-ORDER'
    end

    def exclude?
      periodical? || local? || on_order? || newspaper?
    end

    def serial?
      SERIAL_ITEM_TYPES.include?(item_type) ||
        item_type == 'MICROFORM' && %w(ab as).include?(leader[6..7])
    end

    private

      def base_value
        case classification
        when 'LC', 'LCPER'
          PsulibTraject::Processors::CallNumber::LC.new(value, serial: serial?).reduce
        when 'DEWEY'
          PsulibTraject::Processors::CallNumber::Dewey.new(value).reduce
        else
          PsulibTraject::Processors::CallNumber::Other.new(value).reduce
        end
      end

      def shelf_key
        @shelf_key ||= ShelfKey.new(value)
      end
  end
end
