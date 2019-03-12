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
            sfz = collect_subfield_values(field: f, code: 'z').join ' '
            sf3 = collect_subfield_values(field: f, code: '3').join ' '
            url_label = url_label(sfz, sf3)

            if fulltext_link?(link_type, f.indicator2, url_label)
              collect_subfield_values(field: f, code: 'u')
            elsif partial_link?(link_type, f.indicator2)
              collect_subfield_values(field: f, code: 'u')
            elsif suppl_link?(link_type, f.indicator2, url_label)
              collect_subfield_values(field: f, code: 'u')
            end
          end.flatten.compact

          link_data.map do |link|
            url_match = link.match(%r{https*://([\w*|\.*]*)})
            break nil if url_match.nil?

            domain = serial_solutions_link?(url_match[1]) ? 'serialssolutions.com' : url_match[1]
            accumulator << { text: domain, url: link }.to_json
          end
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

      def partial_link?(link_type, ind2)
        (link_type == 'partial' && ind2 == '1')
      end

      def serial_solutions_link?(link)
        (link == 'sk8es4mc2l.search.serialssolutions.com')
      end

      # The label information present in the catalog.
      def url_label(sfz, sf3)
        [sfz, sf3].join(' ')
      end

      # Extract subfield values.
      def collect_subfield_values(field:, code:)
        field.subfields.select { |sf| sf.code == code }.collect(&:value)
      end
    end
  end
end
