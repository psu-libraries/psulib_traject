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

          link_data = []

          record.fields('856').each do |field|
            break unless sought_link_data_exists?(link_type, field)

            link_data << collect_subfield_values(field: field, code: 'u')
          end

          link_data.flatten.compact.each do |link|
            url_match = link.match(%r{https*://([\w*|\.*]*)})
            break nil if url_match.nil?

            domain = serial_solutions_link?(url_match[1]) ? 'serialssolutions.com' : url_match[1]
            accumulator << { text: domain, url: link }.to_json
          end
        end
      end

      def sought_link_data_exists?(link_type, field)
        sfz = collect_subfield_values(field: field, code: 'z').join ' '
        sf3 = collect_subfield_values(field: field, code: '3').join ' '
        url_label = url_label(sfz, sf3)

        case link_type
        when 'full'
          fulltext_link_available?(field.indicator2, url_label)
        when 'partial'
          partial_link_available?(field.indicator2)
        when 'suppl'
          suppl_link_available?(field.indicator2, url_label)
        else
          false
        end
      end

      def fulltext_link_available?(ind2, url_label)
        ind2 == '0' || !NOT_FULLTEXT.match?(url_label)
      end

      def partial_link_available?(ind2)
        ind2 == '1'
      end

      def suppl_link_available?(ind2, url_label)
        ind2 == '2' && NOT_FULLTEXT.match?(url_label)
      end

      def serial_solutions_link?(link)
        link.casecmp('sk8es4mc2l.search.serialssolutions.com').zero?
      end

      # The label information present in the catalog.
      def url_label(sfz, sf3)
        [sfz, sf3].join(' ')
      end

      # Extract subfield values.
      def collect_subfield_values(field:, code:)
        field.subfields.select { |sf| sf.code == code }.collect(&:value)
      end

      # Extract 949m for access facet
      def extract_access_data
        lambda do |record, accumulator, _context|
          return unless record.fields('949').any?

          access_data = []
          libraries_map = TranslationMap.new('libraries')

          MarcExtractor.cached('949m').collect_matching_lines(record) do |field, spec, extractor|
            library_code = extractor.collect_subfields(field, spec).first
            access_data << case library_code
                           when 'ONLINE'
                             'Online'
                           when 'ACQ_DSL', 'ACQUISTNS', 'SERIAL-SRV'
                             'On Order'
                           when 'ZREMOVED', 'XTERNAL'
                             next
                           else
                             resolve_library_code(field, libraries_map.translate_array([library_code])[0])
                           end
          end
          access_data.compact!
          access_data.uniq!
          access_data.delete('On Order') if not_only_on_order?(access_data)
          accumulator.replace(access_data)
        end
      end

      # If there is anything other than On Order, we DO NOT include On Order
      def not_only_on_order?(access_data)
        access_data.include?('On Order') && (access_data.length > 1)
      end

      def resolve_library_code(field, library)
        return 'Other' if library.nil?

        if !field['l'].nil? && field['l'] == 'ON-ORDER'
          'On Order'
        else
          'In the Library'
        end
      end

      # For media types fields
      def process_media_types
        lambda do |record, accumulator, context|
          return nil unless record.is_a? MARC::Record

          media_types = MarcMediaTypeProcessor.new(record, context).media_types
          accumulator.replace(media_types)
        end
      end
    end
  end
end
