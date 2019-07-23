# frozen_string_literal: true

require 'traject/regex_split'

# A tool for classifying MARC records using a combination of data from the
# record's leader and some 949ts to assign format types to records
class MarcFormatProcessor
  def initialize
    freeze
  end

  # Check 949t, leader6 and 007 formats
  def resolve_formats(record)
    # Check 949t before other formats to avoid overlapping formats,
    # eg. prefer Juvenile Book vs Book, Statute vs Government Document
    formats = resolve_949t record

    overlaps = avoid_overlaps record
    formats = overlaps if !overlaps.empty? && formats.empty?

    formats = resolve_leader(record) if formats.empty?
    formats = resolve_007(record) if formats.empty?

    overrides = resolve_overrides record
    formats = overrides unless overrides.empty?

    # If no other values are present, use the default value "Other"
    formats = 'Other' if formats.empty?

    Array(formats).flatten.compact.uniq
  end

  def avoid_overlaps(record)
    format = ''
    format = 'Instructional Material' if instructional_material?(record)
    # Check Government Document earlier to avoid overlapping with 007 and leader6-7 formats
    format = 'Government Document' if government_document?(record) && format.empty?
    format
  end

  # Check leader byte 6 and byte 7
  def resolve_leader(record)
    formats_leader6_map = Traject::TranslationMap.new('formats_leader6')
    format = formats_leader6_map.translate_array([record.leader[6]])[0]

    case record.leader[6]
    when 'a'
      format = resolve_leader6a record
    when 'g'
      format = resolve_leader6g record
    when 't'
      format = 'Archives/Manuscripts' if %w[a m].include? record.leader[7]
    end

    format.nil? ? '' : format
  end

  def resolve_leader6a(record)
    format = ''

    format = 'Book' if %w[a d m].include? record.leader[7]
    format = 'Journal/Periodical' if %w[b s].include? record.leader[7]
    format = 'Archives/Manuscripts' if record.leader[7] == 'c'
    if record.leader[7] == 'm' && record['008'] && record['008'].value[24..27].include?('m')
      # If decided that it is a Thesis/Dissertation, it is NOT a Book
      format = 'Thesis/Dissertation'
    end

    format
  end

  # Check 008 byte 33 for video
  def resolve_leader6g(record)
    'Video' if record['008'] && %w[m v].include?(record['008'].value[33])
  end

  # Check 007 formats, a record may have multiple 007s
  def resolve_007(record)
    formats = []
    formats_007_map = Traject::TranslationMap.new('formats_007')

    Traject::MarcExtractor.cached('007').collect_matching_lines(record) do |field, _spec, _extractor|
      format = formats_007_map.translate_array([field.value[0]])[0]
      formats << format unless format.nil?
    end

    formats
  end

  # Check 949t formats, a record may have multiple 949s with different 949ts
  def resolve_949t(record)
    formats = []
    formats_949t_map = Traject::TranslationMap.new('formats_949t')

    Traject::MarcExtractor.cached('949t').collect_matching_lines(record) do |field, spec, extractor|
      field_949t = extractor.collect_subfields(field, spec).first
      format = formats_949t_map.translate_array([field_949t])[0]
      formats << format unless format.nil?
    end

    formats
  end

  # Check other possible formats and prefer over 949t, leader6 and 007 formats
  def resolve_overrides(record)
    format = ''
    format = 'Thesis/Dissertation' if thesis? record
    format = 'Newspaper' if newspaper? record
    format = 'Games/Toys' if games? record
    format = 'Proceeding/Congress' if proceeding?(record) || congress?(record)
    format = 'Book' if book? record
    format
  end

  # Check if government document using leader byte 6 and 008 also not university_press?
  def government_document?(record)
    record.leader[6] == 'a' && record['008'] && /[acfilmosz]/.match?(record['008'].value[28]) unless university_press? record
  end

  # Check if 260b OR 264b contain variations of "University Press"
  def university_press?(record)
    field_260b_264b = Traject::MarcExtractor.cached('260b:264b', separator: nil).extract(record)
    field_260b_264b.grep(/University Press/i).any?
  end

  # Check if newspaper using leader byte 7 and 008
  def newspaper?(record)
    record.leader[7] == 's' && record['008'] && record['008'].value[21] == 'n'
  end

  # Checks if it has a 502, if it does it's considered a thesis
  def thesis?(record)
    !record.find { |a| a.tag == '502' }.nil?
  end

  # Check leader byte 12 and 008 byte 29 for proceeding/congress
  def proceeding?(record)
    record.leader[12] == '1' || (record['008'] && record['008'].value[29] == '1')
  end

  # Checks all $6xx for a $v "congress"
  def congress?(record)
    !record.find do |field|
      field.tag.slice(0) == '6' && field.subfields.find { |sf| sf.code == 'v' && regex_to_extract_data_from_a_string(sf.value, /Congress/i) }
    end.nil?
  end

  # Checks leader byte 6 and 16, 006 and 008 for games/toys
  def games?(record)
    %w[r m].include?(record.leader[6]) &&
      (%w[g w].include?(record.leader[16]) ||
      record['006'] && record['006'].value[9] == 'g' ||
      record['008'] && (%w[g w].include?(record['008'].value[33]) || record['008'].value[26] == 'g'))
  end

  # Checks 006 and 008 for instructional material
  def instructional_material?(record)
    record['006'] && record['006'].value[16] == 'q' || record['008'] && record['008'].value[33] == 'q'
  end

  # Override for Book when leader(6-7) is 'am' - issue#172
  def book?(record)
    record.leader[6] == 'a' && record.leader[7] == 'm' && resolve_949t(record).include?('Archives/Manuscripts')
  end
end
