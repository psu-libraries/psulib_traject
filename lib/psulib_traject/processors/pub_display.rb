# frozen_string_literal: true

module PsulibTraject::Processors
  class PubDisplay
    def initialize(field, context)
      @context = context
      @field = field
    end

    def call
      if vern.nil?
        context.output_hash[final] = latin
        # remove duplicate latin version
        context.output_hash.delete("#{field}_latin")
      else
        context.output_hash[final] = [latin.first, vern_clean]
        # remove duplicate versions
        context.output_hash.delete("#{field}_latin")
        context.output_hash.delete("#{field}_vern")
      end
    end

    private

      attr_accessor :context, :field

      def latin
        context.output_hash["#{field}_latin"]
      end

      def vern
        context.output_hash["#{field}_vern"]
      end

      def final
        "#{field}_display_ssm"
      end

      def vern_clean
        vern_value = vern.first
        return vern_value unless /[\u0621-\u064A]+\.$/.match?(vern_value) # regex to check for arabic

        vern_value = vern_value.gsub('.', '')
        ".#{vern_value}"
      end
  end
end
