# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Processors::CallNumber::Dewey do
  subject { described_class.new('1234') }

  its(:scheme) { is_expected.to eq('dewey') }
  its(:reduce) { is_expected.to eq('1234') }
end
