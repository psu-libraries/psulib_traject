# frozen_string_literal: true

require 'traject'
require 'sidekiq'

  class IndexerWorker
    include Sidekiq::Worker

    def perform(filename = nil, collection_name = nil)
      target = Dir[filename]
      # TODO if target is blank, raise an error so that the mourge gets filled up
      target.each do |f|
        IndexFileWorker.perform_async(filename=f, collection_name=collection_name)
      end
    end
  end

  class IndexFileWorker
    include Sidekiq::Worker

    def perform(filename = nil, collection_name = nil)
      indexer = Traject::Indexer::MarcIndexer.new
      indexer.load_config_file('config/traject.rb')
      if collection_name
        url = indexer.settings['solr.url']
        indexer.settings['solr.url'] = url.gsub(url.split('/')[-1], collection_name)
      end
      # if we are passed a collection name we index to it instead of what's in settings
      target = Dir[filename]

      if target.empty?
        indexer.logger.info "#{target} is empty. nothing to index"
      else
        indexer.logger.info  "Indexing #{target}"
        array_of_files = target.collect { |file| File.new(file) }

        if indexer.process array_of_files
          indexed_files = target.join ','
          indexer.logger.info "Indexed #{target}"
        end
      end
    end
  end