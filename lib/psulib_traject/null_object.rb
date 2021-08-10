# frozen_string_literal: true

module PsulibTraject
  class NullObject
    def respond_to_missing?(*)
      self
    end

    def method_missing(*)
      self
    end

    def nil?
      true
    end
    alias :blank? :nil?
    alias :empty? :nil?
  end
end
