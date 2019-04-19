# frozen_string_literal: true

SEPARATOR = '—'.freeze
NOT_FULLTEXT = /addendum|appendices|appendix|appendixes|cover|excerpt|executive summary|index/i.freeze

module Traject
  module Macros
    # A set of custom traject macros (extractors and normalizers)
    module Custom
      # For the hierarchical subject display
      #
      # Split with em dash along v,x,y,z
      def process_subject_hierarchy(fields)
        lambda do |record, accumulator|
          return nil unless record.is_a? MARC::Record

          subjects = []
          split_on_subfield = %w[v x y z]
          Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).first
            unless subject.nil?
              field.subfields.each do |s_field|
                subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if split_on_subfield.include?(s_field.code)
              end
              subject = subject.split(SEPARATOR)
              subject = subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
              subjects << subject # if include_subject
            end
          end

          accumulator.replace(subjects.compact.uniq)
        end
      end

      # For the split subject facet
      #
      # Split with em dash along v,x,y,z
      def process_subject_topic_facet(fields)
        lambda do |record, accumulator|
          return nil unless record.is_a? MARC::Record

          subjects = []
          split_on_subfield = %w[v x y z]
          Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
            subject = extractor.collect_subfields(field, spec).first
            unless subject.nil?
              field.subfields.each do |s_field|
                subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if split_on_subfield.include?(s_field.code)
              end
              subject = subject.split(SEPARATOR)
              subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
            end
          end

          accumulator.replace(subjects.flatten.compact.uniq)
        end
      end

      # For genre facet and display
      #
      # limit to subfield $2 vocabularies for 655|*7 genres
      def process_genre(fields)
        lambda do |record, accumulator|
          return nil unless record.is_a? MARC::Record

          genres = []
          vocabulary = %w[lcgft fast]
          Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
            genre = extractor.collect_subfields(field, spec).first
            include_genre = true
            unless genre.nil?
              include_genre = vocabulary.include?(field['2'].to_s.downcase) if (field.tag == '655') && (field.indicator2 == '7')
              genres << Traject::Macros::Marc21.trim_punctuation(genre) if include_genre
            end
          end

          accumulator.replace(genres).uniq!
        end
      end

      # Extract fulltext links
      def extract_link_data(link_type: 'full')
        lambda do |record, accumulator, _context|
          return unless record.fields('856').any?

          link_data = []

          record.fields('856').each do |field|
            next unless sought_link_data_exists?(link_type, field)

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
    end
  end
end
