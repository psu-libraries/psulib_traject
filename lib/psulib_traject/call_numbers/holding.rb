# frozen_string_literal: true

module PsulibTraject::CallNumbers
  class Holding
    def self.call(record:, context:)
      new(record, context).resolve_base
    end

    attr_reader :record, :context, :holdings

    CallNumber = Struct.new(:value, :classification)

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
    end

    private

      def online?
        context.output_hash['access_facet']&.include?('Online')
      end

      def periodical?(call_number)
        call_number == 'Periodical'
      end

      def local?(call_number)
        call_number.start_with? 'xx('
      end

      def extract_holdings
        Traject::MarcExtractor.cached('949').collect_matching_lines(record) do |field, _spec, _extractor|
          CallNumber.new(field['a'], field['w']) # assuming each 949 has only one subfield a and w
        end
      end

      def resolve_excludes
        holdings.reject! do |call_number|
          local?(call_number.value) ||
          periodical?(call_number.value)
        end
      end

      # @return Array
      def resolve_lop
        return [] if holdings.empty?

        update_holdings

        return holdings.map(&:value) if holdings.one?

        holdings.map! do |call_number|
          case call_number.classification
          when 'LC', 'LCPER'
            PsulibTraject::CallNumbers::LC.new(call_number.value).lopped
          when 'DEWEY'
            PsulibTraject::CallNumbers::Dewey.new(call_number.value).lopped
          else
            PsulibTraject::CallNumbers::Other.new(call_number.value).lopped
          end
        end
        update_holdings

        holdings
      end

      def update_holdings
        holdings.uniq!{ |call_number| call_number.value }
      end

      # def call_number_type
      #   case Traject::MarcExtractor.cached('949w').extract(record).first
      #   when 'LC', 'LCPER'
      #     'LC'
      #   when 'DEWEY'
      #     'DEWEY'
      #   else
      #     'OTHER'
      #   end
      # end

      # # Call number normalization ported from solrmarc code
      # def normalize_call_number(call_number = '')
      #   return call_number unless %w[LC DEWEY].include?(call_number_type) # Normalization only applied to LC/Dewey
      #   call_number = call_number.strip.gsub(/\s\s+/, ' ') # reduce multiple whitespace chars to a single space
      #   call_number = call_number.gsub(/\. \./, ' .') # reduce double periods to a single period
      #   call_number = call_number.gsub(/(\d+\.) ([A-Z])/, '\1\2') # remove space after a period if period is after digits and before letters
      #   call_number.sub(/\.$/, '') # remove trailing period
      # end
  end
end
