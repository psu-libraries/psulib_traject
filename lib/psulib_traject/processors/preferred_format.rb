# frozen_string_literal: true

# A tool for classifying MARC records using a combination of data from the
# record's leader and some 949ts to assign format types to records
module PsulibTraject::Processors
  class PreferredFormat
    def self.call(record:, local_formats:)
      new(record, local_formats)
        .resolve
        .compact
        .uniq
    end

    attr_reader :record, :local_formats

    def initialize(record, local_formats)
      @record = record
      @local_formats = local_formats
      freeze
    end

    def resolve
      format = 'Thesis/Dissertation' if thesis?
      format = 'Newspaper' if newspaper?
      format = 'Games/Toys' if games?
      format = 'Proceeding/Congress' if proceeding? || congress?
      format = 'Book' if book?
      [format]
    end

    private

      # Checks if it has a 502, if it does it's considered a thesis
      def thesis?
        'Thesis/Dissertation' if record.find { |a| a.tag == '502' }
      end

      # Check if newspaper using leader byte 7 and 008
      def newspaper?
        record.leader[7] == 's' && record['008'] && record['008'].value[21] == 'n'
      end

      # Checks leader byte 6 and 16, 006 and 008 for games/toys
      def games?
        %w[r m].include?(record.leader[6]) &&
          (%w[g w].include?(record.leader[16]) ||
           record['006'] && record['006'].value[9] == 'g' ||
           record['008'] && (%w[g w].include?(record['008'].value[33]) || record['008'].value[26] == 'g'))
      end

      # Check leader byte 12 and 008 byte 29 for proceeding/congress
      def proceeding?
        record.leader[12] == '1' || (record['008'] && record['008'].value[29] == '1')
      end

      # Checks all $6xx for a $v "congress"
      def congress?
        record.find do |field|
          field
            .tag
            .slice(0) == '6' &&
            field
              .subfields
              .find { |sf| sf.code == 'v' && PsulibTraject.regex_to_extract_data_from_a_string(sf.value, /Congress/i) }
        end
      end

      # Override for Book when leader(6-7) is 'am' - issue#172
      def book?
        record.leader[6] == 'a' && record.leader[7] == 'm' && local_formats.include?('Archives/Manuscripts')
      end
  end
end
