# frozen_string_literal: true

module PsulibTraject
  module Processors
    class OclcExtract
      attr_accessor :record, :accumulator

      def initialize(record, accumulator)
        @record = record
        @accumulator = accumulator
      end

      def extract_deprecated_oclcs
        record.fields(%w(035 019)).each do |field|
          case field.tag
          when '019'
            get_019_deprecated_oclcs(field, accumulator)
          when '035'
            get_035_deprecated_oclcs(field, accumulator)
          end
        end
        accumulator.uniq!
      end

      def extract_primary_oclc
        record.fields(['035']).each do |field|
          get_035_primary_oclc(field, accumulator)
          accumulator.uniq!
        end
      end

      private

        def get_035_primary_oclc(field, accumulator)
          unless field&.[]('a').nil?
            if includes_oclc_indicators?(field['a'])
              subfield = PsulibTraject.regex_split(field['a'], //).map { |x| x[/\d+/] }.compact.join
            end
            accumulator << subfield
          end
        end

        def get_019_deprecated_oclcs(field, accumulator)
          field.subfields.each do |subfield|
            if subfield.code == 'a' && !subfield.value.nil? &&
                !subfield.value.empty? && subfield.value.match(/^[0-9]{3,15}$/)
              accumulator << subfield.value
            end
          end
        end

        def get_035_deprecated_oclcs(field, accumulator)
          field.subfields.each do |subfield|
            if subfield.code == 'z' && !subfield.value.nil? &&
                !subfield.value.empty? && includes_oclc_indicators?(subfield.value)
              subfield_cleaned = PsulibTraject.regex_split(subfield.value, //).map { |x| x[/\d+/] }.compact.join
              accumulator << subfield_cleaned
            end
          end
        end

        def includes_oclc_indicators?(sf_a)
          sf_a.include?('OCoLC') ||
            sf_a.include?('ocn') ||
            sf_a.include?('ocm') ||
            sf_a.include?('OCLC')
        end
    end
  end
end
