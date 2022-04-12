# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Workers::IncrementalsIndexer do
  let(:indexer) { described_class }

  before(:all) do
    redis = Redis.new
    redis.keys('incrementals:*').map { |key| redis.del(key) }
  end

  before do
    ConfigSettings.symphony_data_path = './spec/fixtures'
  end

  describe '#perform' do
    before do
      stub_request(
        :post, /.*#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}.*/
      )
        .to_return(
          status: 200,
          body: '',
          headers: {}
        )
      stub_request(
        :get, /.*#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}\/solr\/psul_catalog\/update\/json\?commit=true/
      )
        .to_return(
          status: 200,
          body: '',
          headers: {}
        )
    end

    it 'performs Indexer jobs' do
      indexer.perform_now
      expect(WebMock).to have_requested(
        :post, "http://#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}/solr/psul_catalog/update/json"
      )
        .times(4)
      expect(WebMock).to have_requested(
        :post, "http://#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}/solr/psul_catalog/update/json"
      )
        .with(body: '{"delete":"1234"}').times(2)
      expect(WebMock).to have_requested(
        :post, "http://#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}/solr/psul_catalog/update/json"
      )
        .with(body: '{"delete":"1235"}').times(1)
    end

    it 'does not perform the job a second time' do
      indexer.perform_now
      expect(WebMock).to have_requested(
        :post, "http://#{ConfigSettings.solr.host}:#{ConfigSettings.solr.port}/solr/psul_catalog/update/json"
      ).times(0)
    end
  end
end
