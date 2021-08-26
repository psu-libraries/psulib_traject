# frozen_string_literal: true

module PsulibTraject::Macros::Subjects
  SEPARATOR = '—'

  # A set of custom traject macros (extractors and normalizers)
  # For the hierarchical subject display
  #
  # Split with em dash along v,x,y,z
  def process_subject_hierarchy(fields)
    lambda do |record, accumulator|
      return nil unless record.is_a? MARC::Record

      subjects = []
      split_on_subfield = %w[v x y z]
      Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
        subject = extractor.collect_subfields(field, spec).first
        unless subject.nil?
          field.subfields.each do |s_field|
            subject = add_subject_separator(subject, s_field) if split_on_subfield.include?(s_field.code)
          end
          subject = subject.split(SEPARATOR)
          subject = subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }.join(SEPARATOR)
          subjects << subject # if include_subject
        end
      end

      accumulator.replace(subjects.compact.uniq)
    end
  end

  # For the split subject facet
  #
  # Split with em dash along v,x,y,z
  def process_subject_topic_facet(fields)
    lambda do |record, accumulator|
      return nil unless record.is_a? MARC::Record

      subjects = []
      split_on_subfield = %w[v x y z]
      Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
        subject = extractor.collect_subfields(field, spec).first
        unless subject.nil?
          field.subfields.each do |s_field|
            subject = add_subject_separator(subject, s_field) if split_on_subfield.include?(s_field.code)
          end
          subject = subject.split(SEPARATOR)
          subjects << subject.map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
        end
      end

      accumulator.replace(subjects.flatten.compact.uniq)
    end
  end

  def add_subject_separator(subject, s_field)
    subject.gsub(" #{s_field.value}", "#{SEPARATOR}#{s_field.value}")
  end
end
