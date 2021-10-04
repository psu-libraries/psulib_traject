# frozen_string_literal: true

RSpec::Matchers.define :reduce_to do |expected|
  match do |actual|
    described_class.new(actual).reduce == expected
  end
  failure_message do |actual|
    "expected #{actual} to reduce to #{expected} but got #{described_class.new(actual).reduce} instead."
  end
end

RSpec::Matchers.define :serial_reduce_to do |expected|
  match do |actual|
    described_class.new(actual, serial: true).reduce == expected
  end
  failure_message do |actual|
    "expected #{actual} to reduce to #{expected} but got #{described_class.new(actual).reduce} instead."
  end
end
