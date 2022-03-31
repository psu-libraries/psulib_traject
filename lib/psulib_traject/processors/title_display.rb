# frozen_string_literal: true

module PsulibTraject::Processors
  class TitleDisplay
    def initialize(context)
      @context = context
    end

    def call
      if title_vern.nil?
        context.output_hash['title_display_ssm'] = title_latin
        # remove duplicate latin title
        context.output_hash.delete('title_latin_display_ssm')
      else
        context.output_hash['title_display_ssm'] = title_vern_clean
        # remove duplicate vern title
        context.output_hash.delete('title_vern')
      end
    end

    private

      attr_accessor :context

      def title_latin
        context.output_hash['title_latin_display_ssm']
      end

      def title_vern
        context.output_hash['title_vern']
      end

      def title_vern_clean
        # Remove right to left arabic equals sign and replacing with
        # regular equals sign to display properly
        title_vern.map { |s| s.gsub(' =‏ ‏', ' = ') }
      end
  end
end
