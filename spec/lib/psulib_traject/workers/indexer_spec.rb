# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PsulibTraject::Workers::Indexer do
  let!(:marc_file) { Pathname.new(Tempfile.new(['', '.mrc'], directory)) }

  let(:indexer) { described_class.new }
  let(:directory) { Dir.mktmpdir }
  let(:dev_null) { IO.sysopen('/dev/null', 'w+') }

  let(:mock_traject_indexer) do
    instance_spy(
      Traject::Indexer::MarcIndexer,
      logger: Logger.new(dev_null),
      settings: { 'solr.url' => 'http://localhost:8993/solr/psul_catalog' }
    )
  end

  before do
    allow(Traject::Indexer::MarcIndexer).to receive(:new).and_return(mock_traject_indexer)
    allow(mock_traject_indexer).to receive(:load_config_file)
  end

  describe '#perform' do
    context 'with a directory of files' do
      it 'submits an array of files to the indexer' do
        indexer.perform(directory)
        expect(mock_traject_indexer).to have_received(:process).with([kind_of(File)])
      end
    end

    context 'with a single file' do
      it 'processes the file with a Traject indexer' do
        indexer.perform(marc_file)
        expect(mock_traject_indexer).to have_received(:process).with([kind_of(File)])
      end
    end

    context 'when specifying a Solr collection' do
      it 'processes the file using the specified collection' do
        indexer.perform(marc_file, 'my_collection')
        expect(mock_traject_indexer.settings['solr.url']).to eq('http://localhost:8993/solr/my_collection')
        expect(mock_traject_indexer).to have_received(:process).with([kind_of(File)])
      end
    end
  end
end
