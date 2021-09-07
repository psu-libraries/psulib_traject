# frozen_string_literal: true

module PsulibTraject
  class SubjectHeading
    SEPARATOR = '—'

    def initialize(headings)
      @headings = headings
    end

    def length
      @headings.count
    end

    def value
      @headings.join(SEPARATOR)
    end

    def <=>(heading)
      length <=> heading.length
    end
  end
end
