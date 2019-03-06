# frozen_string_literal: true

SEPARATOR = '—'.freeze

# For the hierarchical subject/genre display
#
# Split with em dash along v,x,y,z
# Optional vocabulary argument for whitelisting subfield $2 vocabularies
def process_hierarchy(record, fields, vocabulary = [])
  return nil unless record.is_a? MARC::Record
  
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
  return nil unless record.is_a? MARC::Record

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

# For genre facet and display
#
# limit to subfield $2 vocabularies for 655|*7 genres
def process_genre(record, fields)
  return nil unless record.is_a? MARC::Record

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

  if pub_date.nil?
    # Nothing from 008, try 264 and 260
    field264c = Traject::MarcExtractor.cached('264|*1|c', separator: nil).extract(record).first
    field260c = Traject::MarcExtractor.cached('260c', separator: nil).extract(record).first
    pub_date = marc_date_processor.check_elsewhere field264c, field260c
  end

  # Ignore dates below min_year (default 500) or above max_year (this year plus 6 years)
  pub_date && (pub_date > MIN_YEAR || pub_date < MAX_YEAR) ? pub_date : nil
end

# For formats and resources fields
def process_formats(record)
  return nil unless record.is_a? MARC::Record

  marc_format_processor = MarcFormatProcessor.new(record)
  marc_format_processor.formats
end
