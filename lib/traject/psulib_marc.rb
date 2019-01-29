SEPARATOR = '—'.freeze

# for the hierarchical subject display
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
