# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

RSpec.describe PsulibTraject::Workers::HourlyIndexer do
  let(:indexer) { described_class }

  before(:all) do
    redis = Redis.new
    redis.keys('hr:*').map { |key| redis.del(key) }
  end

  before do
    ConfigSettings.symphony_data_path = './spec/fixtures'
  end

  describe '#perform' do
    it 'submits jobs for each hourly file' do
      indexer.perform_async
      expect(described_class).to have_enqueued_sidekiq_job
    end

    it 'increases the size of the job queue' do
      expect do
        described_class.perform_async
      end.to change(described_class.jobs, :size).by(1)
    end

    it 'performs Indexer jobs' do
      indexer.perform_now
      expect(PsulibTraject::Workers::Indexer.jobs.size).to eq(2)
    end

    it 'does not perform the job a second time' do
      indexer.perform_now
      expect(PsulibTraject::Workers::Indexer.jobs.size).to eq(0)
    end
  end
end
