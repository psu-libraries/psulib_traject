# frozen_string_literal: true

# A tool for classifying MARC records using a combination of data from the
# record's leader and some 949ts to assign format types to records
module PsulibTraject::Processors
  class Format
    def self.call(record:)
      new(record).resolve_formats
    end

    attr_reader :record

    def initialize(record)
      @record = record
      freeze
    end

    # Check 949t, leader6 and 007 formats
    def resolve_formats
      # Check 949t before other formats to avoid overlapping formats,
      # eg. prefer Juvenile Book vs Book, Statute vs Government Document
      formats = local_formats

      overlaps = avoid_overlaps
      formats = overlaps if overlaps && formats.empty?

      formats = type_of_record if formats.empty?
      formats = physical_description if formats.nil?

      overrides = resolve_overrides
      formats = overrides if overrides

      # If no other values are present, use the default value "Other"
      formats = 'Other' if formats.empty?

      Array(formats).flatten.compact.uniq
    end

    # Check Government Document earlier to avoid overlapping with 007 and leader6-7 formats
    def avoid_overlaps
      if instructional_material?
        'Instructional Material'
      elsif government_document?
        'Government Document'
      end
    end

    # Resolve leader byte 6
    def type_of_record
      case record.leader[6..7]
      when /^a/
        bibliographic_level
      when /^g/
        type_of_visual_material
      when /^t(a|m)/
        'Archives/Manuscripts'
      else
        Traject::TranslationMap
          .new('formats_leader6')
          .translate_array([record.leader[6]])
          .first
      end
    end

    # Resolve leader byte 7
    def bibliographic_level
      case record.leader[7]
      when 'a'
        'Article'
      when 'b', 's'
        'Journal/Periodical'
      when 'c'
        'Archives/Manuscripts'
      when 'd'
        'Book'
      when 'm'
        thesis_or_book
      else
        ''
      end
    end

    # If decided that it is a Thesis/Dissertation, it is NOT a Book
    def thesis_or_book
      if record['008'] && record['008'].value[24..27].include?('m')
        'Thesis/Dissertation'
      else
        'Book'
      end
    end

    # Check 008 byte 33 for video
    def type_of_visual_material
      'Video' if record['008'] && %w[m v].include?(record['008'].value[33])
    end

    # Check 007 formats, a record may have multiple 007s
    def physical_description
      [].tap do |formats|
        Traject::MarcExtractor.cached('007').collect_matching_lines(record) do |field, _spec, _extractor|
          format = Traject::TranslationMap.new('formats_007').translate_array([field.value[0]])[0]
          formats << format if format
        end
      end
    end

    # Check 949t formats, a record may have multiple 949s with different 949ts
    def local_formats
      [].tap do |formats|
        Traject::MarcExtractor.cached('949t').collect_matching_lines(record) do |field, spec, extractor|
          field_949t = extractor.collect_subfields(field, spec).first
          format = Traject::TranslationMap.new('formats_949t').translate_array([field_949t])[0]
          formats << format if format
        end
      end
    end

    # Check other possible formats and prefer over 949t, leader6 and 007 formats
    def resolve_overrides
      format = 'Thesis/Dissertation' if thesis?
      format = 'Newspaper' if newspaper?
      format = 'Games/Toys' if games?
      format = 'Proceeding/Congress' if proceeding? || congress?
      format = 'Book' if book?
      format
    end

    private

      # Check if government document using leader byte 6 and 008 also not university_press?
      def government_document?
        unless university_press?
          record.leader[6] == 'a' && record['008'] && /[acfilmosz]/.match?(record['008'].value[28])
        end
      end

      # Check if 260b OR 264b contain variations of "University Press"
      def university_press?
        field_260b_264b = Traject::MarcExtractor.cached('260b:264b', separator: nil).extract(record)
        field_260b_264b.grep(/\buniversity\b/i).any?
      end

      # Check if newspaper using leader byte 7 and 008
      def newspaper?
        record.leader[7] == 's' && record['008'] && record['008'].value[21] == 'n'
      end

      # Checks if it has a 502, if it does it's considered a thesis
      def thesis?
        !record.find { |a| a.tag == '502' }.nil?
      end

      # Check leader byte 12 and 008 byte 29 for proceeding/congress
      def proceeding?
        record.leader[12] == '1' || (record['008'] && record['008'].value[29] == '1')
      end

      # Checks all $6xx for a $v "congress"
      def congress?
        !record.find do |field|
          field.tag.slice(0) == '6' && field.subfields.find { |sf| sf.code == 'v' && PsulibTraject.regex_to_extract_data_from_a_string(sf.value, /Congress/i) }
        end.nil?
      end

      # Checks leader byte 6 and 16, 006 and 008 for games/toys
      def games?
        %w[r m].include?(record.leader[6]) &&
          (%w[g w].include?(record.leader[16]) ||
           record['006'] && record['006'].value[9] == 'g' ||
           record['008'] && (%w[g w].include?(record['008'].value[33]) || record['008'].value[26] == 'g'))
      end

      # Checks 006 and 008 for instructional material
      def instructional_material?
        record['006'] && record['006'].value[16] == 'q' || record['008'] && record['008'].value[33] == 'q'
      end

      # Override for Book when leader(6-7) is 'am' - issue#172
      def book?
        record.leader[6] == 'a' && record.leader[7] == 'm' && local_formats.include?('Archives/Manuscripts')
      end
  end
end
