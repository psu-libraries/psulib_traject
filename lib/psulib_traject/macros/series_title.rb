# frozen_string_literal: true

module PsulibTraject::Macros::SeriesTitle
  def extract_series_title
    lambda do |record, accumulator|
      index_string = []
      fields = record.fields

      if fields.tags.include?('830')
        index_string << '830adfghklmnoprstvwxy3'
        if fields.tags.include?('490') && record.fields('490').first.indicator1 == " " || record.fields('490').first.indicator1 == '0'
          index_string << ':490avlx'
        end
      else
        if fields.tags.include?('490')
          index_string << '490avlx'
        end
      end

      if fields.tags.include?('440')
        index_string << ':' unless index_string.blank?
        index_string << '440anpvx'
      end

      extractor = Traject::MarcExtractor.new(index_string.join(''))
      extractor.extract(record).each do |item|
        accumulator << item
      end
    end
  end
end