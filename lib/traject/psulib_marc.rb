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

ESTIMATE_TOLERANCE = 15
MIN_YEAR = 500
MAX_YEAR = Time.new.year + 6

# For publication year facet
#
# Using Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic
#    but check for 264|*1|c before 260c
def process_publication_date(record)
  field008 = Traject::MarcExtractor.cached('008').extract(record).first
  found_date = process_008_date field008

  if found_date.nil?
    # Nothing from 008, try 264 and 260
    field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
    field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
    found_date = process_264_260_date field264c, field260c
  end

  # Ignore dates below min_year (default 500) or above max_year (this year plus 6 years)
  found_date = nil if found_date && (found_date < MIN_YEAR || found_date > MAX_YEAR)

  found_date
end

# For publication year facet
#
# If 008 represents a date range, will take the midpoint of the range,
#     only if range is smaller than estimate_tolerance, default 15 years.
def process_008_date(field008)
  return nil unless field008 && field008.length >= 11

  date_type = field008.slice(6)
  date1_str = field008.slice(7, 4)
  date2_str = field008.slice(11, 4) if field008.length > 15

  found_date = get_008q(date1_str, date2_str, date_type)
  found_date = get_008_other(date1_str, date2_str, date_type) if found_date.nil?

  found_date
end

# For publication year facet
#
# For date_type q=questionable, resolve range.
def get_008q(date1_str, date2_str, date_type)
  return nil unless date_type == 'q'

  found_date = nil
  # make unknown digits at the beginning or end of range
  date1 = date1_str.sub('u', '0').to_i
  date2 = date2_str.sub('u', '9').to_i
  # do we have a range we can use?
  is_range = (date2 > date1) && ((date2 - date1) <= ESTIMATE_TOLERANCE)
  found_date = (date2 + date1) / 2 if is_range

  found_date
end

# For publication year facet
#
# Anything OTHER than date_type n=unknown, q=questionable try single date
def get_008_other(date1_str, date2_str, date_type)
  return nil if %w[n q].include?(date_type)

  # second date is original publication date for date_type r
  date_str = %w[r p].include?(date_type) && date2_str.to_i != 0 ? date2_str : date1_str
  resolve_date date_str
end

# For publication year facet
#
# Resolve single date
#   u's means range, find midpoint and check tolerance
def resolve_date(date_str)
  return nil if date_str.nil?

  found_date = nil
  u_count = date_str.count 'u'
  # replace unknown digits with 0
  date = date_str.tr('u', '0').to_i
  if u_count > 0 && date != 0
    delta = 10**u_count # 10^u_count, exponent
    found_date = date + (delta / 2) if delta <= ESTIMATE_TOLERANCE
  elsif date != 0
    found_date = date
  end

  found_date
end

# For publication year facet
#
# Check 264|*1|c then 260c for a date
def process_264_260_date(field264c, field260c)
  found_date = nil

  date = field264c || field260c
  # take the first four digits
  match = /(\d{4})/.match(date)
  found_date = match[1].to_i if match

  found_date
end
