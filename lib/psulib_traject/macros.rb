# frozen_string_literal: true

NOT_FULLTEXT = /addendum|appendices|appendix|appendixes|cover|excerpt|executive summary|index/i.freeze
PSU_THESIS_CODE = /THESIS-B|THESIS-D|THESIS-M/.freeze
ESTIMATE_TOLERANCE = 15
MIN_YEAR = 500
MAX_YEAR = Time.new.year + 6

module PsulibTraject
  module Macros
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
            if (field.tag == '655') && (field.indicator2 == '7')
              include_genre = vocabulary.include?(field['2'].to_s.downcase)
            end
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

        link_data_all = []
        record.fields('856').each do |field|
          next unless sought_link_data_exists?(link_type, field)

          link_data_all << collect_link_data(field)
        end

        link_data_all.each do |link_data|
          link_data[:url].flatten.compact.each do |link|
            link = "http://#{link}" if link.start_with?('www.')

            url_match = url_match(link)
            next if url_match.nil?

            accumulator << generate_link(link, link_data, url_match)
          end
        end
      end
    end

    def generate_link(link, link_data, url_match)
      {
        prefix: link_data[:prefix] || '',
        text: special_collections_text(link) || link_data[:text] || link_domain(url_match),
        url: link, notes: link_data[:notes]
      }.to_json
    end

    def url_match(link)
      url_match = PsulibTraject.regex_split link, %r{https*://([\w.]*)}i
      url_match[1]
    end

    def link_domain(link)
      serial_solutions_link?(link) ? 'serialssolutions.com' : link
    end

    def collect_link_data(field)
      {
        url: collect_subfield_values(field: field, code: 'u'),
        prefix: collect_subfield_values(field: field, code: '3').first,
        text: collect_subfield_values(field: field, code: 'y').first,
        notes: collect_subfield_values(field: field, code: 'z').join(' ')
      }
    end

    def sought_link_data_exists?(link_type, field)
      url_label = ''

      if %w[full partial].include? link_type
        sfz = collect_subfield_values(field: field, code: 'z').join ' '
        sf3 = collect_subfield_values(field: field, code: '3').join ' '
        url_label = url_label(sfz, sf3)
      end

      case link_type
      when 'full'
        fulltext_link_available?(field.indicator1, field.indicator2, url_label)
      when 'partial'
        partial_link_available?(field.indicator2, url_label)
      when 'suppl'
        suppl_link_available?(field.indicator2)
      else
        false
      end
    end

    def fulltext_link_available?(ind1, ind2, url_label)
      (ind2 == '0' || ind2.strip.empty? || (ind1.strip.empty? && ind2.strip.empty?)) && !NOT_FULLTEXT.match?(url_label)
    end

    def partial_link_available?(ind2, url_label)
      ind2 == '1' || (ind2 == '0' && NOT_FULLTEXT.match?(url_label))
    end

    def suppl_link_available?(ind2)
      ind2 == '2'
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
      field.subfields.select { |sf| sf.code == code }.map(&:value)
    end

    # Feed the record to the MarcPubDateProcessor class to find the publication year.
    #
    # Refactor of Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic but check for 264|*1|c before
    # 260c.
    def process_publication_date
      lambda do |record, accumulator|
        return nil unless record.is_a? MARC::Record

        processor = Processors::PubDate.new

        field008 = Traject::MarcExtractor.cached('008').extract(record).first
        pub_date = processor.find_date(field008)

        if pub_date.nil?
          # Nothing from 008, try 264 and 260
          field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
          field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
          pub_date = processor.check_elsewhere field264c, field260c
        end

        publication_date = pub_date_in_range(pub_date)
        accumulator << publication_date if publication_date
      end
    end

    # Extract OCLC number
    def extract_oclc_number
      lambda do |record, accumulator|
        Processors::OclcExtract.new(record, accumulator).extract_primary_oclc
      end
    end

    def exclude_locations
      lambda do |_record, accumulator|
        accumulator.reject! { |value| ConfigSettings.location_excludes.include?(value) }
        accumulator.compact!
      end
    end

    def include_psu_theses_only
      lambda do |record, accumulator|
        accumulator.clear unless psu_thesis?(record)
        accumulator.compact!
      end
    end

    # Extract deprecated OCLCs
    def extract_deprecated_oclcs
      lambda do |record, accumulator|
        Processors::OclcExtract.new(record, accumulator).extract_deprecated_oclcs
      end
    end

    private

      def special_collections_text(link)
        'Special Collections Materials' if link.match?(/ark:\/42409\/fa8/)

        nil
      end

      def psu_thesis?(record)
        record.fields('949').each do |field|
          field.subfields.each do |subfield|
            return true if subfield.code == 't' && PSU_THESIS_CODE.match?(subfield.value)
          end
        end

        false
      end

      # Ignore dates below MIN_YEAR (default 500) or above MAX_YEAR (this year plus 6 years)
      def pub_date_in_range(pub_date)
        pub_date && pub_date >= MIN_YEAR && pub_date <= MAX_YEAR ? pub_date : nil
      end
  end
end
