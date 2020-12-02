# frozen_string_literal: true

SEPARATOR = '—'
NOT_FULLTEXT = /addendum|appendices|appendix|appendixes|cover|excerpt|executive summary|index/i.freeze
ESTIMATE_TOLERANCE = 15
MIN_YEAR = 500
MAX_YEAR = Time.new.year + 6
PubDateProcessor = MarcPubDateProcessor.new

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
                subject = add_subject_separator(subject, s_field) if split_on_subfield.include?(s_field.code)
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
                subject = add_subject_separator(subject, s_field) if split_on_subfield.include?(s_field.code)
              end
              subject = subject.split(SEPARATOR)
              subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
            end
          end

          accumulator.replace(subjects.flatten.compact.uniq)
        end
      end

      def add_subject_separator(subject, s_field)
        subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
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

          link_data = []

          record.fields('856').each do |field|
            next unless sought_link_data_exists?(link_type, field)

            link_data << collect_subfield_values(field: field, code: 'u')
          end
          link_data.flatten.compact.each do |link|
            url_match = regex_split link, %r{https*://([\w.]*)}
            next if url_match[1].nil?

            domain = serial_solutions_link?(url_match[1]) ? 'serialssolutions.com' : url_match[1]
            accumulator << { text: domain, url: link }.to_json
          end
        end
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
          partial_link_available?(field.indicator1, field.indicator2, url_label)
        when 'suppl'
          suppl_link_available?(field.indicator2)
        else
          false
        end
      end

      def fulltext_link_available?(ind1, ind2, url_label)
        (ind2 == '0' || ind1 == '4') && !NOT_FULLTEXT.match?(url_label)
      end

      def partial_link_available?(ind1, ind2, url_label)
        ind2 == '1' || ((ind2 == '0' || ind1 == '4') && NOT_FULLTEXT.match?(url_label))
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
        field.subfields.select { |sf| sf.code == code }.collect(&:value)
      end

      # Feed the record to the MarcPubDateProcessor class to find the publication year.
      #
      # Refactor of Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic but check for 264|*1|c before
      # 260c.
      def process_publication_date
        lambda do |record, accumulator|
          return nil unless record.is_a? MARC::Record

          field008 = Traject::MarcExtractor.cached('008').extract(record).first
          pub_date = PubDateProcessor.find_date(field008)

          if pub_date.nil?
            # Nothing from 008, try 264 and 260
            field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
            field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
            pub_date = PubDateProcessor.check_elsewhere field264c, field260c
          end

          publication_date = pub_date_in_range(pub_date)
          accumulator << publication_date if publication_date
        end
      end

      # Ignore dates below min_year (default 500) or above max_year (this year plus 6 years)
      def pub_date_in_range(pub_date)
        pub_date && (pub_date > MIN_YEAR || pub_date < MAX_YEAR) ? pub_date : nil
      end

      # Extract OCLC number
      def extract_oclc_number
        lambda do |record, accumulator|
          record.fields(['035']).each do |field|
            unless field&.[]('a').nil?
              if Custom.includes_oclc_indicators?(field['a'])
                subfield = regex_split(field['a'], //).map { |x| x[/\d+/] }.compact.join('')
              end
              accumulator << subfield
            end
            accumulator.uniq!
          end
        end
      end

      def self.includes_oclc_indicators?(sf_a)
        sf_a.include?('OCoLC') ||
          sf_a.include?('ocn') ||
          sf_a.include?('ocm') ||
          sf_a.include?('OCLC')
      end

      def extract_hathi_data
        lambda do |_record, accumulator, context|
          oclc_number = context.output_hash&.dig('oclc_number_ssim')&.first.to_i.to_s
          ht_hash = ht_find oclc_number
          accumulator << ht_hash.to_json unless ht_hash.nil?
        end
      end

      def hathi_to_hash(ht_format)
        hathi_overlap_csv = "#{settings['hathi_overlap_path']}final_hathi_#{ht_format}_overlap.csv"
        CSV.read(hathi_overlap_csv)
           .group_by(&:shift)
           .each do |_oclc, ht_data|
          ht_data.map! { |data| [ht_key(ht_format), :access].zip(data).to_h }
                 .uniq! { |data| data[:access] }
          ht_data.reject! { |data| data[:access] == ht_reject(ht_format) } if ht_data.length > 1
        end
      end

      def exclude_locations
        lambda do |_record, accumulator|
          accumulator.reject! { |value| ConfigSettings.location_excludes.include?(value) }
          accumulator.compact!
        end
      end

      private

      def ht_find(oclc_number)
        HATHI_MULTI_OVERLAP&.dig(oclc_number)&.first || HATHI_MONO_OVERLAP&.dig(oclc_number)&.first
      end

      def ht_key(ht_format)
        ht_format == 'mono' ? :ht_id : :ht_bib_key
      end

      def ht_reject(ht_format)
        ht_format == 'mono' ? 'deny' : 'allow'
      end
    end
  end
end
