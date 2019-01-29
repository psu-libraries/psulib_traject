SEPARATOR = '—'.freeze

# for the hierarchical subject/genre display
# split with em dash along v,x,y,z
# optional vocabulary argument for whitelisting subfield $2 vocabularies
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

# for the split subject facet
# split with em dash along v,x,y,z
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

# for publication year facet
# using Traject::Macros::Marc21Semantics#marc_publication_date as the basic logic
# only to add a check for 264|*1|c before 260c
def process_publication_date(record, options = {})
  estimate_tolerance  = options[:estimate_tolerance] || 15
  min_year            = options[:min_year] || 500
  max_year            = options[:max_year] || (Time.new.year + 6)

  field008 = Traject::MarcExtractor.cached('008').extract(record).first
  found_date = nil

  if field008 && field008.length >= 11
    date_type = field008.slice(6)
    date1_str = field008.slice(7,4)
    date2_str = field008.slice(11, 4) if field008.length > 15

    # for date_type q=questionable, we have a range.
    if date_type == 'q'
      # make unknown digits at the beginning or end of range,
      date1 = date1_str.sub('u', '0').to_i
      date2 = date2_str.sub('u', '9').to_i
      # do we have a range we can use?
      if (date2 > date1) && ((date2 - date1) <= estimate_tolerance)
        found_date = (date2 + date1) / 2
      end
    end
    # didn't find a date that way, and anything OTHER than date_type
    # n=unknown, q=questionable, try single date -- for some date types,
    # there's a date range between date1 and date2, yeah, we often take
    # the FIRST date then, the earliest. That's just what we're doing.
    if found_date.nil? && date_type != 'n' && date_type != 'q'
      # in date_type 'r', second date is original publication date, use that I think?
      date_str = ((date_type == 'r' || date_type == 'p') && date2_str.to_i != 0) ? date2_str : date1_str
      # Deal with stupid 'u's, which end up meaning a range too,
      # find midpoint and make sure our tolerance is okay.
      ucount = 0
      while (!date_str.nil?) && (i = date_str.index('u'))
        ucount += 1
        date_str[i] = '0'
      end
      date = date_str.to_i
      if ucount > 0 && date != 0
        delta = 10**ucount # 10^ucount, expontent
        if delta <= estimate_tolerance
          found_date = date + (delta / 2)
        end
      elsif date != 0
        found_date = date
      end
    end
  end
  # nothing from 008, try 264|*1|c then 260c
  if found_date.nil?
    v264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
    v260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
    date = v264c || v260c
    # just try to take the first four digits
    if (m = /(\d{4})/.match(date))
      found_date = m[1].to_i
    end
  end

  # is it within our acceptable range?
  found_date = nil if found_date && (found_date < min_year || found_date > max_year)

  found_date
end
