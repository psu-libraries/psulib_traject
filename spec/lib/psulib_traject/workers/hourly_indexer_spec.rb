# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Workers::HourlyIndexer, skip: ci_build? do
  let(:indexer) { described_class.new }

  describe '#perform' do
    it 'submits jobs for each hourly file' do
      # TBD
      indexer.perform
    end
  end
end
