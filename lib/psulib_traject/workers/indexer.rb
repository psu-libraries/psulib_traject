# frozen_string_literal: true

module PsulibTraject
  module Workers
    class Indexer < Base
      # @param [Hash] args
      # @option args [String, Pathname] :filename (required)
      # @option args [String] :collection_name
      def perform(filename, opts = {})
        path = Pathname.new(filename)
        files = marc_files(path)
        process(files, opts[:collection_name])
      end

      private

        def marc_files(path)
          if path.directory?
            path
              .children
              .select { |filename| filename.extname == '.mrc' }
              .map { |file| File.new(file) }
          else
            [File.new(path)]
          end
        end

        def process(files, collection_name)
          indexer = Traject::Indexer::MarcIndexer.new
          indexer.load_config_file('config/traject.rb')

          # if we are passed a collection name we index to it instead of what's in settings
          if collection_name
            url = indexer.settings['solr.url']
            indexer.settings['solr.url'] = url.gsub(url.split('/')[-1], collection_name)
          end

          indexer.logger.info "Indexing #{files.length} files"
          indexer.process files
        end
    end
  end
end
