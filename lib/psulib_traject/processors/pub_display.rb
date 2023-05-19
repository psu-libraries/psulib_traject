# frozen_string_literal: true

module PsulibTraject::Processors
  class PubDisplay
    def initialize(field, context)
      @context = context
      @field = field
    end

    def call
      return if final.nil?

      final[1] = vern_clean unless vern.nil?
    end

    private

      attr_accessor :context, :field

      def vern
        final.length <= 1 ? nil : final[1]
      end

      def final
        context.output_hash["#{field}_display_ssm"]
      end

      def vern_clean
        return vern unless /[\u0621-\u064A]+\.$/.match?(vern) # regex to check for arabic

        vern_value = vern.gsub('.', '')
        ".#{vern_value}"
      end
  end
end
