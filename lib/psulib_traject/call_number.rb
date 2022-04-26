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

    DEWEY_KLASS_PREFIX = 'AAA'

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

    def normalized_shelfkey
      shelf_key.normalized
    end

    def not_browsable?
      return true unless lc? || dewey?

      normalized_shelfkey.nil?
    end

    def keymap
      {
        call_number:    value,
        classification: classification,
        key:            normalized_shelfkey
      }
    end

    def periodical?
      value.match?(/^\^?Periodical/i)
    end

    def newspaper?
      value.match?(/Newspaper/i)
    end

    def local?
      value.match?(/^xx/i)
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

    def solr_field
      "call_number_#{classification_to_field}_ssm"
    end

    def shelfkey_field
      "#{classification_to_field}_shelfkey"
    end

    private

      def base_value
        case classification
        when 'LC', 'LCPER'
          PsulibTraject::Processors::CallNumber::LC.new(value, serial: serial?).reduce
        when 'DEWEY'
          PsulibTraject::Processors::CallNumber::Dewey.new(value, serial: serial?).reduce
        else
          PsulibTraject::Processors::CallNumber::Other.new(value).reduce
        end
      end

      def lc?
        %w[LC LCPER].include? classification
      end

      def dewey?
        classification == 'DEWEY'
      end

      def classification_to_field
        return 'lc' if lc?

        classification.downcase
      end

      # @note Adding a prefix to dewey call number so to be able to use lcsort to create shelf keys
      def prefix
        return '' unless dewey?

        DEWEY_KLASS_PREFIX
      end

      def shelf_key
        @shelf_key ||= ShelfKey.new(value, prefix: prefix)
      end
  end
end
