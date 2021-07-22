# frozen_string_literal: true

module PsulibTraject::CallNumbers
  class Holding
    def self.call(record:, context:)
      new(record, context).resolve_base
    end

    attr_reader :record, :context, :holdings

    def initialize(record, context)
      @record = record
      @context = context
      @holdings = extract_holdings
      freeze
    end

    def resolve_base
      return [] if online? || holdings.empty?

      resolve_excludes
      resolve_lop

      holdings.map(&:value).uniq
    end

    private

      def online?
        context.output_hash['access_facet']&.include?('Online')
      end

      def periodical?(call_number)
        call_number == 'Periodical'
      end

      def on_order?(location)
        location == 'ON-ORDER'
      end

      def local?(call_number)
        call_number.start_with? 'xx('
      end

      # assuming each 949 has only one subfield a, w and l
      def extract_holdings
        Traject::MarcExtractor.cached('949').collect_matching_lines(record) do |field, _spec, _extractor|
          CallNumber.new(
            value: field['a'],
            classification: field['w'],
            location: field['l']
          )
        end
      end

      def resolve_excludes
        holdings.reject! do |call_number|
          local?(call_number.value) ||
          periodical?(call_number.value) ||
          on_order?(call_number.location)
        end
      end

      # @return Array
      def resolve_lop
        return if holdings.one?

        holdings.each(&:lop)
      end
  end
end
