# frozen_string_literal: true

module PsulibTraject
  class IndexFileWorker < Worker
    def perform(filename = nil, collection_name = nil)
      indexer = Traject::Indexer::MarcIndexer.new
      indexer.load_config_file('config/traject.rb')
      # if we are passed a collection name we index to it instead of what's in settings
      if collection_name
        url = indexer.settings['solr.url']
        indexer.settings['solr.url'] = url.gsub(url.split('/')[-1], collection_name)
      end

      target = Dir[filename]

      if target.empty?
        indexer.logger.info "#{target} is empty. nothing to index"
      else
        indexer.logger.info "Indexing #{target}"
        array_of_files = target.map { |file| File.new(file) }

        if indexer.process array_of_files
          indexer.logger.info "Indexed #{target}"
        end
      end
    end
  end
end
