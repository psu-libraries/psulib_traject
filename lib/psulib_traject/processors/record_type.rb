# frozen_string_literal: true

module PsulibTraject::Processors
  class RecordType
    def self.call(record:, current_formats: [])
      if current_formats.any? && !current_formats.include?(Traject::TranslationMap.new('formats_949t')['MICROFORM'])
        return current_formats
      end

      new_formats = new(record, current_formats).resolve

      current_formats
        .push(new_formats)
        .compact
    end

    attr_reader :record, :current_formats

    def initialize(record, current_formats)
      @record = record
      @current_formats = current_formats
      freeze
    end

    def resolve
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

    private

      def bibliographic_level
        case record.leader[7]
        when 'a'
          'Article'
        when 'b', 's'
          'Journal/Periodical'
        when 'c'
          'Archives/Manuscripts'
        when 'd'
          book
        when 'm'
          thesis_or_book
        end
      end

      # If decided that it is a Thesis/Dissertation, it is NOT a Book
      def thesis_or_book
        if record['008'] && record['008'].value[24..27].include?('m')
          'Thesis/Dissertation'
        else
          book
        end
      end

      # Check 008 byte 33 for video
      def type_of_visual_material
        'Video' if record['008'] && %w[m v].include?(record['008'].value[33])
      end

      def book
        'Book' unless current_formats.include?(Traject::TranslationMap.new('formats_949t')['JUVENILEBK'])
      end
  end
end
