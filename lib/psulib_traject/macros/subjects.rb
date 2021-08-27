# frozen_string_literal: true

module PsulibTraject::Macros::Subjects
  SEPARATOR = '—'
  SUBFIELD_SPLIT = %w[v x y z].freeze

  # A set of custom traject macros (extractors and normalizers)
  # For the hierarchical subject display
  #
  # Split with em dash along v,x,y,z
  def process_subject_hierarchy(fields)
    lambda do |record, accumulator|
      return unless record.is_a? MARC::Record

      subjects = []
      Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
        subjects << extract_subjects(field, spec, extractor).join(SEPARATOR)
      end
      accumulator.replace(subjects.compact.uniq)
    end
  end

  def process_subject_browse_facet(standard_fields:, pst_fields:)
    lambda do |record, accumulator|
      return unless record.is_a? MARC::Record

      subjects = []
      Traject::MarcExtractor.cached(standard_fields).collect_matching_lines(record) do |field, spec, extractor|
        subjects << extract_subjects(field, spec, extractor).join(SEPARATOR)
      end

      Traject::MarcExtractor.cached(pst_fields).collect_matching_lines(record) do |field, spec, extractor|
        if field.indicator2 == '7' && (field['2'] || '').match?(/pst/i)
          subjects << extract_subjects(field, spec, extractor).join(SEPARATOR)
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
      return unless record.is_a? MARC::Record

      subjects = []
      Traject::MarcExtractor.cached(fields).collect_matching_lines(record) do |field, spec, extractor|
        subjects << extract_subjects(field, spec, extractor)
      end

      accumulator.replace(subjects.flatten.compact.uniq)
    end
  end

  def extract_subjects(field, spec, extractor)
    subject = extractor.collect_subfields(field, spec).first
    return if subject.nil?

    field.subfields.each do |subfield|
      if SUBFIELD_SPLIT.include?(subfield.code)
        subject = subject.gsub(" #{subfield.value}", "#{SEPARATOR}#{subfield.value}")
      end
    end

    subject
      .split(SEPARATOR)
      .map { |s| Traject::Macros::Marc21.trim_punctuation(s) }
  end
end
