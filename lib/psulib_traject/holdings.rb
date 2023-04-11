# frozen_string_literal: true

module PsulibTraject
  class Holdings
    # @param record [Marc::Record]
    # @param context [Traject::Indexer::Context]
    # @return [Array<CallNumber>]
    def self.call(record:, context:)
      new(
        record: record,
        context: context
      ).resolve_base
    end

    attr_reader :record, :context, :holdings

    def initialize(record:, context:)
      @record = record
      @context = context
      @holdings = extract_holdings
      freeze
    end

    def resolve_base
      return [] if not_in_the_library? || holdings.empty?

      holdings.reject! do |call_number|
        call_number.exclude? || call_number.not_browsable?
      end

      if holdings.one?
        holdings
      else
        holdings
          .each(&:reduce!)
          .uniq(&:value)
      end
    end

    private

      def not_in_the_library?
        !context.output_hash['access_facet']&.include?('In the Library')
      end

      # assuming each 949 has only one subfield a, w and l
      def extract_holdings
        Traject::MarcExtractor.cached('949').collect_matching_lines(record) do |field, _spec, _extractor|
          CallNumber.new(
            value: field['a'],
            classification: field['w'],
            location: field['l'],
            item_type: field['t'],
            leader: record.leader
          )
        end
      end
  end
end
