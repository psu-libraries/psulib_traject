# frozen_string_literal: true

module PsulibTraject
  class Holdings
    # @param record [Marc::Record]
    # @param context [Traject::Indexer::Context]
    # @param classification [Array<String>] Returns call numbers only for given classifications, example: 'LC', 'LCPER',
    #   'DEWEY'. Defaults to [], which return any classification.
    # @return [Array<CallNumber>]
    def self.call(record:, context:, classification: [])
      new(
        record: record,
        context: context,
        classification: Array(classification)
      ).resolve_base
    end

    attr_reader :record, :context, :holdings, :classification

    def initialize(record:, context:, classification:)
      @record = record
      @context = context
      @holdings = extract_holdings
      @classification = classification
      freeze
    end

    def resolve_base
      return [] if online? || holdings.empty?

      holdings.reject! { |call_number| call_number.exclude? || classification_not_requested?(call_number) }

      if holdings.one?
        holdings
      else
        holdings
          .each(&:reduce!)
          .uniq(&:value)
      end
    end

    private

      def online?
        context.output_hash['access_facet']&.include?('Online')
      end

      def classification_not_requested?(call_number)
        return false if classification.empty?

        !classification.include?(call_number.classification)
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
