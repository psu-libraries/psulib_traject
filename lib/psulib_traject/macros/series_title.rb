# frozen_string_literal: true

module PsulibTraject::Macros::SeriesTitle
  def extract_series_title_display
    lambda do |record, accumulator|
      index_string = []
      fields = record.fields

      if fields.tags.include?('830')
        index_string << '830adfghklmnoprstvwxy3'
        if append_490?(fields, record)
          index_string << ':490avlx'
        end
      elsif fields.tags.include?('490')
        index_string = ['490avlx']
      end

      if fields.tags.include?('440')
        index_string = ['440anpvx']
      end

      extractor = Traject::MarcExtractor.new(index_string.join(''))
      extractor.extract(record).each do |item|
        accumulator << item
      end
      accumulator.map! { |s| Traject::Macros::Marc21.trim_punctuation(s) }
    end
  end

  private

    def append_490?(fields, record)
      fields.tags.include?('490') &&
        (record.fields('490').first&.indicator1 == ' ' ||
        record.fields('490').first&.indicator1 == '0')
    end
end
