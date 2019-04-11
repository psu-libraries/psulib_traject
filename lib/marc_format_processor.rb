# frozen_string_literal: true

# A tool for classifying MARC records using a combination of data from the
# record's leader and some 949ts to assign format types to records
class MarcFormatProcessor
  attr_reader :record, :formats

  def set_formats(record)
    @record = record
    resolve_formats
    resolve_overrides
    resolve_other

    @formats = Array(@formats) unless @formats.is_a? Array
    @formats.compact.uniq
  end

  # Check 949t, leader6 and 007 formats
  def resolve_formats
    # Check 949t before other formats to avoid overlapping formats,
    # eg. prefer Juvenile Book vs Book, Statute vs Government Document
    @formats = resolve_949t

    @formats = 'Instructional Material' if instructional_material? && @formats.empty?

    # Check Government Document earlier to avoid overlapping with 007 and leader6-7 formats
    @formats = 'Government Document' if government_document? && @formats.empty?

    @formats = resolve_leader if @formats.empty?
    @formats = resolve_007 if @formats.empty?
  end

  # Check leader byte 6 and byte 7
  def resolve_leader
    formats_leader6_map = Traject::TranslationMap.new('formats_leader6')
    format = formats_leader6_map.translate_array([record.leader[6]])[0]

    case record.leader[6]
    when 'a'
      format = resolve_leader6a
    when 'g'
      format = resolve_leader6g
    when 't'
      format = 'Archives/Manuscripts' if %w[a m].include? record.leader[7]
    end

    format.nil? ? '' : format
  end

  def resolve_leader6a
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
  def resolve_leader6g
    'Video' if record['008'] && %w[m v].include?(record['008'].value[33])
  end

  # Check 007 formats, a record may have multiple 007s
  def resolve_007
    formats = []
    formats_007_map = Traject::TranslationMap.new('formats_007')

    Traject::MarcExtractor.cached('007').collect_matching_lines(record) do |field, _spec, _extractor|
      format = formats_007_map.translate_array([field.value[0]])[0]
      formats << format unless format.nil?
    end

    formats.uniq
  end

  # Check 949t formats, a record may have multiple 949s with different 949ts
  def resolve_949t
    formats = []
    formats_949t_map = Traject::TranslationMap.new('formats_949t')

    Traject::MarcExtractor.cached('949t').collect_matching_lines(record) do |field, spec, extractor|
      field_949t = extractor.collect_subfields(field, spec).first
      format = formats_949t_map.translate_array([field_949t])[0]
      formats << format unless format.nil?
    end

    formats.uniq
  end

  # Check other possible formats and prefer over 949t, leader6 and 007 formats
  def resolve_overrides
    @formats = 'Thesis/Dissertation' if thesis?
    @formats = 'Newspaper' if newspaper?
    @formats = 'Games/Toys' if games?
    @formats = 'Proceeding/Congress' if proceeding? || congress?
  end

  # If no other values are present, use the default value "Other"
  def resolve_other
    @formats = 'Other' if @formats.nil? || @formats.empty?
  end

  # Check if government document using leader byte 6 and 008 also not university_press?
  def government_document?
    record.leader[6] == 'a' && record['008'] && /[acfilmosz]/.match?(record['008'].value[28]) unless university_press?
  end

  # Check if 260b OR 264b contain variations of "University Press"
  def university_press?
    field_260b_264b = Traject::MarcExtractor.cached('260b:264b', separator: nil).extract(record)
    field_260b_264b.grep(/University Press/i).any?
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
      field.tag.slice(0) == '6' && field.subfields.find { |sf| sf.code == 'v' && /Congress/i.match(sf.value) }
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
end
