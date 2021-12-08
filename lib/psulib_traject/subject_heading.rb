# frozen_string_literal: true

module PsulibTraject
  class SubjectHeading
    SEPARATOR = '—'

    attr_reader :tag, :headings

    def initialize(headings, tag: nil)
      @headings = headings
      @tag = tag
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
