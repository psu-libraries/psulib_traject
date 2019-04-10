# frozen_string_literal: true

# A tool for classifying MARC records using a combination of data from the
# record's leader and some 949ts to assign media types to records
class MarcMediaTypeProcessor

  def initialize
    freeze
  end

  def resolve_media_types(record, access_facet)
    media_types = []

    media_types << resolve_949a(record)
    media_types << resolve_007(record, access_facet)
    media_types << resolve_538a(record)
    media_types << resolve_300b_347b(record)
    media_types << resolve_300a_338a(record)
    media_types << resolve_300a(record)
    media_types << resolve_300(record)

    media_types.flatten.compact.uniq
  end

  # Check 949a types, a record may have multiple 949s with different 949a's
  def resolve_949a(record)
    media_types = []

    Traject::MarcExtractor.cached('949a').collect_matching_lines(record) do |field, spec, extractor|
      field_949a = extractor.collect_subfields(field, spec).first
      media_types << 'Blu-ray' if field_949a =~ /BLU-RAY/i
      media_types << 'Videocassette (VHS)' if field_949a =~ Regexp.union(/ZVC/i, /ARTVC/i, /MVC/i)
      media_types << 'DVD' if field_949a =~ Regexp.union(/ZDVD/i, /ARTDVD/i, /MDVD/i, /ADVD/i, /DVD/i)
      media_types << 'Videocassette' if field_949a =~ /AVC/i
      media_types << 'Laser disc' if field_949a =~ Regexp.union(/ZVD/i, /MVD/i)
    end

    media_types
  end

  # Check 007 media types, a record may have multiple 007s
  def resolve_007(record, access_facet)
    media_types = []

    Traject::MarcExtractor.cached('007').collect_matching_lines(record) do |field, _spec, _extractor|
      media_types << case field.value[0]
                     when 'g'
                       'Slide' if field.value[1] == 's'
                     when 'h'
                       'Microfilm/Microfiche'
                     when 'k'
                       'Photo' if field.value[1] == 'h'
                     when 'm'
                       'Film'
                     when 'r'
                       'Remote-sensing image'
                     when 's'
                       resolve_007_byte1(field) if in_the_library?(access_facet)
                     when 'v'
                       resolve_007_byte4(field)
                     end
    end

    media_types
  end

  def in_the_library?(access_facet)
    Array(access_facet).include? 'In the Library'
  end

  def resolve_007_byte1(field007)
    return nil if field007.value[1].nil?

    media_type = case field007.value[1]
                 when 'd'
                   resolve_007_byte3 field007
                 when 'e'
                   'Cylinder'
                 when 'w'
                   'Wire recording'
                 else
                   resolve_007_byte1_other(field007)
                 end
    media_type || nil
  end

  def resolve_007_byte1_other(field007)
    if field007.value[6] == 'j'
      'Audiocassette'
    elsif field007.value[1] == 'q'
      'Piano/Organ roll'
    end
  end

  def resolve_007_byte3(field007)
    return nil if field007.value[3].nil?

    media_007_3_map = Traject::TranslationMap.new('media_007_3')
    media_type = media_007_3_map.translate_array([field007.value[3]])[0]
    media_type || nil
  end

  def resolve_007_byte4(field007)
    return nil if field007.value[4].nil?

    media_007_4_map = Traject::TranslationMap.new('media_007_4')
    media_type = media_007_4_map.translate_array([field007.value[4]])[0]
    media_type || 'Other video'
  end

  def resolve_538a(record)
    media_types = []

    Traject::MarcExtractor.cached('538a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
      field_538a = extractor.collect_subfields(field, spec).first
      media_types << 'Blu-ray' if field_538a =~ Regexp.union(/Bluray/i, /Blu-ray/i, /Blu ray/i)
      media_types << 'Videocassette (VHS)' if field_538a =~ /VHS/i
      media_types << 'DVD' if field_538a =~ /DVD/i
      media_types << 'Laser disc' if field_538a =~ Regexp.union(/CAV/i, /CLV/i)
      media_types << 'Video CD' if field_538a =~ Regexp.union(/VCD/i, /Video CD/i, /VideoCD/i)
    end

    media_types
  end

  def resolve_300b_347b(record)
    media_types = []

    Traject::MarcExtractor.cached('300b:347b', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
      field_300b_347b = extractor.collect_subfields(field, spec).first
      media_types << 'MPEG-4' if field_300b_347b =~ /MP4/i
      media_types << 'Video CD' if field_300b_347b =~ Regexp.union(/VCD/i, /Video CD/i, /VideoCD/i)
    end

    media_types
  end

  def resolve_300a_338a(record)
    media_types = []

    Traject::MarcExtractor.cached('300a:338a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
      field_300a_338a = extractor.collect_subfields(field, spec).first
      media_types << 'Piano/Organ roll' if field_300a_338a =~ Regexp.union(/audio roll/i, /piano roll/i, /organ roll/i)
    end

    media_types
  end

  def resolve_300a(record)
    media_types = []

    Traject::MarcExtractor.cached('300a', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
      field300a = extractor.collect_subfields(field, spec).first
      media_types << 'Microfilm/Microfiche' if field300a =~ Regexp.union(/microfilm/i, /microfiche/i)
      media_types << 'Photo' if field300a =~ /photograph/i
      media_types << 'Remote-sensing image' if field300a =~ Regexp.union(/remote-sensing image/i, /remote sensing image/i)
      media_types << 'Slide' if field300a =~ /slide/i
    end

    media_types
  end

  def resolve_300(record)
    media_types = []

    Traject::MarcExtractor.cached('300abcdefghijklmnopqrstuvwxyz', alternate_script: false).collect_matching_lines(record) do |field, spec, extractor|
      field300 = extractor.collect_subfields(field, spec).first
      if field300 =~ %r{(sound|audio) discs? (\((ca. )?\d+.*\))?\D+((digital|CD audio)\D*[,\;.])? (c )?(4 3/4|12 c)}
        media_types << 'CD' unless field300 =~ /(DVD|SACD|blu[- ]?ray)/
      end

      media_types << 'Vinyl disc' if field300 =~ %r{33(\.3| 1/3) ?rpm} && field300 =~ /(10|12) ?in/
    end

    media_types
  end
end
