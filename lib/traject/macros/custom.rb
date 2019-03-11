# frozen_string_literal: true

module Traject
  module Macros
    # A set of custom traject macros (extractors and normalizers)
    module Custom
      NOT_FULLTEXT = /addendum|appendices|appendix|appendixes|cover|excerpt|executive summary|index/i.freeze

      # Extract fulltext links
      def extract_link_data(link_type: 'full')
        lambda do |record, accumulator, _context|
          return unless record.fields('856').any?

          link_data = record.fields('856').map do |f|
            url_label = url_label(f['z'], f['3'])

            if fulltext_link?(link_type, f.indicator2, url_label)
              collect_subfield_values(field: f, code: 'u')
            elsif suppl_link?(link_type, f.indicator2, url_label)
              collect_subfield_values(field: f, code: 'u')
            end
          end.flatten

          next unless link_data.any?

          accumulator << link_data.map { |link| link_ary_maker url: link }.inject(:merge).to_json
        end
      end

      def fulltext_link?(link_type, ind2, url_label)
        (link_type == 'full' &&
            (ind2 == '0' || !NOT_FULLTEXT.match?(url_label))
        )
      end

      def suppl_link?(link_type, ind2, url_label)
        (link_type == 'suppl' &&
            (ind2 == '2' && NOT_FULLTEXT.match?(url_label))
        )
      end

      # The label information present in the catalog.
      def url_label(sfz, sf3)
        [sfz, sf3].join(' ')
      end

      # Make a JSON object for link creation.
      def link_ary_maker(url:)
        domain = String.new(url.match(%r{https*://([\w*|\.*]*)})[1])
        { text: domain, url: url }
      end

      # Extract subfield values.
      def collect_subfield_values(field:, code:)
        field.subfields.select { |sf| sf.code == code }.collect(&:value)
      end
    end
  end
end
