# frozen_string_literal: true

module PsulibTraject
  module Workers
    class IncrementalIndexer < Base
      def perform
        perform_indexes
        perform_deletes
      end

      def incremental_directory
        @incremental_directory ||= Pathname
          .new(ConfigSettings.symphony_data_path)
          .join(ConfigSettings.symphony_incremental_subdir)
      end

      def perform_deletes
        current_collection = PsulibTraject::SolrManager.new.current_collection

        target_deletes = Dir.glob("#{incremental_directory}/**/*_deletes_*.txt").sort

        processed_deletes = redis.keys("#{current_collection}:*").map { |e| e.gsub("#{current_collection}:", '') }
        files_to_process = target_deletes - processed_deletes

        indexer.logger.info "Found #{files_to_process.length} files to process for deletes"

        files_to_process.each do |file_name|
          File
            .read(file_name)
            .split("\n")
            .map { |id| delete(id) }
          redis.set("#{current_collection}:#{file_name}", true)
          redis.expire("#{current_collection}:#{file_name}", ConfigSettings.incremental_skip_expire_seconds.to_i)
        end
      end

      def delete(id)
        indexer.writer.delete(id)
        indexer.logger.info "Deleted ID #{id}"
      end

      def perform_indexes
        current_collection = PsulibTraject::SolrManager.new.current_collection
        target_files = Dir.glob("#{incremental_directory}/**/*.m*rc").sort

        indexed_files = redis.keys("#{current_collection}:*").map { |e| e.gsub("#{current_collection}:", '') }
        files_to_index = target_files - indexed_files

        indexer.logger.info "Found #{files_to_index.length} files to index"
        array_of_files = files_to_index.map { |file| File.new(file) }

        indexer.process array_of_files

        files_to_index.each do |file_name|
          indexer.logger.info "marking #{file_name} as done"
          redis.set("#{current_collection}:#{file_name}", true)
          redis.expire("#{current_collection}:#{file_name}", ConfigSettings.incremental_skip_expire_seconds.to_i)
        end
      end
    end
  end
end
