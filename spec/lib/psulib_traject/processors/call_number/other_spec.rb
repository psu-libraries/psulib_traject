# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Processors::CallNumber::Other do
  subject { described_class.new('1234') }

  its(:reduce) { is_expected.to eq('1234') }
end
