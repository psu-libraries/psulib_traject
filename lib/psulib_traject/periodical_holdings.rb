# frozen_string_literal: true

module PsulibTraject
  class PeriodicalHoldings
    def self.tags
      {
        heading: '852',
        summary: '866',
        supplemental: '867',
        index: '868'
      }
    end

    attr_accessor :heading

    def initialize
      @summaries = []
      @supplementals = []
      @indices = []
    end

    def library
      heading['b']
    end

    def location
      heading['c']
    end

    def call_number
      [heading['h'], heading['i']]
        .join(' ')
        .gsub(/\s$/, '')
    end

    def in_use?
      !heading.nil?
    end

    def add_summary(field)
      @summaries << field
    end

    def summary
      @summaries.map { |field| field['a'] }
    end

    def add_supplement(field)
      @supplementals << field
    end

    def supplement
      @supplementals.map { |field| field['a'] }
    end

    def add_index(field)
      @indices << field
    end

    def index
      @indices.map { |field| field['a'] }
    end

    def to_hash
      {
        library: library,
        location: location
      }.merge(summary_data)
    end

    def summary_data
      {
        call_number: call_number,
        summary: summary,
        supplement: supplement,
        index: index
      }
    end
  end
end
