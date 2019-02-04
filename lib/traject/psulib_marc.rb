SEPARATOR = '—'.freeze

# For the hierarchical subject/genre display
#
# Split with em dash along v,x,y,z
# Optional vocabulary argument for whitelisting subfield $2 vocabularies
def process_hierarchy(record, fields, vocabulary = [])
  subjects = []
  split_on_subfield = %w[v x y z]
  Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
    subject = extractor.collect_subfields(field, spec).first
    include_subject = vocabulary.empty? # always include the subject if a vocabulary is not specified
    unless subject.nil?
      field.subfields.each do |s_field|
        # when specified, only include subject if it is part of the vocabulary
        include_subject = vocabulary.include?(s_field.value) if s_field.code == '2' && !vocabulary.empty?
        subject = subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}") if split_on_subfield.include?(s_field.code)
      end
      subject = subject.split(SEPARATOR)
      subject = subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
      subjects << subject if include_subject
    end
  end
  subjects
end

# For the split subject facet
#
# Split with em dash along v,x,y,z
def process_subject_topic_facet(record, fields)
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
  subjects.flatten
end

# for genre facet and display
# limit to subfield $2 vocabularies for 655|*7 genres
def process_genre(record, fields)
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
  genres
end

ESTIMATE_TOLERANCE = 15
MIN_YEAR = 500
MAX_YEAR = Time.new.year + 6

# Feed the record to the MarcPubDateProcessor class to find the publication year.
#
# Refactor of Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic but check for 264|*1|c before
# 260c.
def process_publication_date(record)
  return nil unless record.is_a? MARC::Record

  field008 = Traject::MarcExtractor.cached('008').extract(record).first
  marc_date_processor = MarcPubDateProcessor.new(field008)
  pub_date = marc_date_processor.find_date

  if marc_date_processor.find_date.nil?
    # Nothing from 008, try 264 and 260
    field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
    field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
    pub_date = marc_date_processor.check_elsewhere field264c, field260c
  end

  # Ignore dates below min_year (default 500) or above max_year (this year plus 6 years)
  pub_date && (pub_date > MIN_YEAR || pub_date < MAX_YEAR) ? pub_date : nil
end

# For determining the single three to four digit publication year.
#
# If 008 represents a date range, will take the midpoint of the range, only if range is smaller than estimate_tolerance,
# default 15 years.
#
# @param field008 [String] The 008 field from the Marc record
# @return nil if field008 is not set
# @return [Integer] if the field's date can be found, the year found
class MarcPubDateProcessor
  attr_accessor :field008, :date_type, :date1, :date2

  def initialize(field008)
    @field008 = field008
    return unless @field008 && @field008.length >= 11

    @date_type = field008.slice(6)
    @date1_str = field008.slice(7, 4)
    @date2_str = field008.length > 15 ? field008.slice(11, 4) : ''
  end

  # Based on the date_type, return the proper value.
  def find_date
    return nil if @date_type.nil?

    case @date_type
    when 'p', 'r'
      # Reissue/reprint/re-recording, etc.
      date_str = @date2_str.to_i != 0 ? @date2_str : @date1_str
      resolve_date date_str
    when 'q'
      # Questionable
      resolve_range
    else
      # Default case, just resolve the first date.
      resolve_date @date1_str
    end
  end

  # For when we are dealing with ranges.
  def resolve_range
    # Make unknown digits at the beginning or end of range
    date1 = @date1_str.sub('u', '0').to_i
    date2 = @date2_str.sub('u', '9').to_i
    # Do we have a range we can use?
    is_range = (date2 > date1) && ((date2 - date1) <= ESTIMATE_TOLERANCE)
    (date2 + date1) / 2 if is_range
  end

  # Resolve single date u's means range, find midpoint and check tolerance
  def resolve_date(date_str)
    u_count = date_str.count 'u'
    # Replace unknown digits with 0.
    date = date_str.tr('u', '0').to_i
    if u_count.positive? && date != 0
      delta = 10**u_count # 10^u_count, exponent
      date + (delta / 2) if delta <= ESTIMATE_TOLERANCE
    elsif date != 0
      date
    end
  end

  # In case looking at the 008 failed, check 264|*1|c then 260c for a date.
  def check_elsewhere(field264c, field260c)
    date = field264c || field260c
    # Take the first four digits.
    match = /(\d{4})/.match(date)
    match[1].to_i if match
  end
end
