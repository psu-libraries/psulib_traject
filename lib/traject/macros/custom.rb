# frozen_string_literal: true

# A set of custom traject macros (extractors and normalizers)
module Traject
  module Macros
    module Custom
      NOT_FULLTEXT = /addendum|appendices|appendix|appendixes|cover|excerpt|executive summary|index/i

      # Extract fulltext links
      def extract_link_data(link_type: 'full')
        lambda do |record, accumulator, _context|
          return unless record.fields('856').any?

          link_data = record.fields('856').map do |f|
            url_label = url_label(f['z'], f['3'])

            if f.indicator2 == '0' || NOT_FULLTEXT.!~(url_label) # Fulltext here
              return unless link_type == 'full'
              collect_subfield_values(field: f, code: 'u')
            elsif f.indicator2 == '2' || NOT_FULLTEXT.~(url_label) # Supplemental here
              collect_subfield_values(field: f, code: 'u')
            end

          end.flatten

          next unless link_data.any?
          accumulator << link_data.map {|link| link_ary_maker url: link }.to_json
        end
      end

      # The label information present in the catalog.
      def url_label(sfz, sf3)
        [sfz, sf3].join(' ')
      end

      # Make a JSON object for link creation.
      def link_ary_maker(url:)
        domain = String.new(url.match(/https*:\/\/([\w*|\.*]*)/)[1])
        {text: domain, url: url}
      end

      # Extract subfield values.
      def collect_subfield_values(field:, code:)
        field.subfields.reject {|sf| sf.code != code}.collect {|sf| sf.value}
      end

    end
  end
end
