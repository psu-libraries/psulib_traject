# frozen_string_literal: true

# A tool for classifying MARC records using a combination of data from the record's leader and some 949ts to assign
# media types to records
module PsulibTraject::Processors
  class MediaType
    def self.call(record:, access_facet:)
      new(record, access_facet).resolve
    end

    attr_reader :record, :access_facet

    def initialize(record, access_facet)
      @record = record
      @access_facet = access_facet
      freeze
    end

    def resolve
      (
        resolve_949a |
        resolve_007 |
        resolve_538a |
        resolve_300b_347b |
        resolve_300a_338a |
        resolve_300a |
        resolve_300
      ).compact
    end

    # Check 949a types, a record may have multiple 949s with different 949a's
    def resolve_949a
      [].tap do |results|
        Traject::MarcExtractor.cached('949a').collect_matching_lines(record) do |field, spec, extractor|
          field_949a = extractor.collect_subfields(field, spec).first
          results << 'Blu-ray' if /BLU-RAY/i.match?(field_949a)
          results << 'Videocassette (VHS)' if field_949a&.match?(Regexp.union(/ZVC/i, /ARTVC/i, /MVC/i))
          results << 'DVD' if field_949a&.match?(Regexp.union(/ZDVD/i, /ARTDVD/i, /MDVD/i, /ADVD/i, /DVD/i))
          results << 'Laser disc' if field_949a&.match?(Regexp.union(/ZVD/i, /MVD/i))
        end
      end
    end

    # Check 007 media types, a record may have multiple 007s
    def resolve_007
      [].tap do |results|
        Traject::MarcExtractor.cached('007').collect_matching_lines(record) do |field, _spec, _extractor|
          results << case field.value[0]
                     when 'g'
                       'Slide' if field.value[1] == 's'
                     when 'k'
                       'Photo' if field.value[1] == 'h'
                     when 'm'
                       'Film'
                     when 'r'
                       'Remote-sensing image'
                     when 's'
                       resolve_007_byte1(field) if in_the_library?
                     when 'v'
                       resolve_007_byte4(field)
                     end
        end
      end
    end

    def resolve_538a
      [].tap do |results|
        Traject::MarcExtractor.cached('538a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
          field_538a = extractor.collect_subfields(field, spec).first
          results << 'Blu-ray' if field_538a&.match?(Regexp.union(/Bluray/i, /Blu-ray/i, /Blu ray/i))
          results << 'Videocassette (VHS)' if /VHS/i.match?(field_538a)
          results << 'DVD' if /DVD/i.match?(field_538a)
          results << 'Video CD' if field_538a&.match?(Regexp.union(/VCD/i, /Video CD/i, /VideoCD/i))
        end
      end
    end

    def resolve_300b_347b
      [].tap do |results|
        Traject::MarcExtractor.cached('300b:347b', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
          field_300b_347b = extractor.collect_subfields(field, spec).first
          results << 'MPEG-4' if /MP4/i.match?(field_300b_347b)
          results << 'Video CD' if field_300b_347b&.match?(Regexp.union(/VCD/i, /Video CD/i, /VideoCD/i))
        end
      end
    end

    def resolve_300a_338a
      [].tap do |results|
        Traject::MarcExtractor.cached('300a:338a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
          field_300a_338a = extractor.collect_subfields(field, spec).first
          results << 'Piano/Organ roll' if field_300a_338a&.match?(Regexp.union(/audio roll/i, /piano roll/i, /organ roll/i))
        end
      end
    end

    def resolve_300a
      [].tap do |results|
        Traject::MarcExtractor.cached('300a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
          field300a = extractor.collect_subfields(field, spec).first
          results << 'Photo' if /photograph/i.match?(field300a)
          if field300a&.match?(Regexp.union(/remote-sensing image/i, /remote sensing image/i))
            results << 'Remote-sensing image'
          end
          results << 'Slide' if /slide/i.match?(field300a)
        end
      end
    end

    def resolve_300
      [].tap do |results|
        Traject::MarcExtractor.cached('300abcdefghijklmnopqrstuvwxyz', alternate_script: false)
          .collect_matching_lines(record) do |field, spec, extractor|
            field300 = extractor.collect_subfields(field, spec).first

            if %r{(sound|audio) discs? (\((ca. )?\d+.*\))?\D+((digital|CD audio)\D*[,;.])? (c )?(4 3/4|12 c)}.match?(field300) && field300 !~ /(DVD|SACD|blu[- ]?ray)/
              results << 'CD'
            end
            results << 'Vinyl disc' if field300 =~ %r{33(\.3| 1/3) ?rpm} && field300 =~ /(10|12) ?in/
          end
      end
    end

    private

      def in_the_library?
        Array(access_facet).include? 'In the Library'
      end

      def resolve_007_byte1(field007)
        return if field007.value[1].nil?

        case field007.value[1]
        when 'd'
          resolve_007_byte3 field007
        when 'e'
          'Cylinder'
        when 'w'
          'Wire recording'
        else
          resolve_007_byte1_other(field007)
        end
      end

      def resolve_007_byte1_other(field007)
        if field007.value[6] == 'j'
          'Audiocassette'
        elsif field007.value[1] == 'q'
          'Piano/Organ roll'
        end
      end

      def resolve_007_byte3(field007)
        return if field007.value[3].nil?

        media_007_3_map = Traject::TranslationMap.new('media_007_3')
        media_007_3_map.translate_array([field007.value[3]])[0]
      end

      def resolve_007_byte4(field007)
        return if field007.value[4].nil?

        media_007_4_map = Traject::TranslationMap.new('media_007_4')
        media_007_4_map.translate_array([field007.value[4]])[0] || 'Other video'
      end
  end
end
