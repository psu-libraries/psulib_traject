# frozen_string_literal: true

module PsulibTraject
  module Workers
    class HourlyIndexer < Base
      def perform
        perform_indexes
        perform_deletes
      end

      def hourlies_directory
        @hourlies_directory ||= Pathname
          .new(ConfigSettings.symphony_data_path)
          .join(ConfigSettings.symphony_hourlies_subdir)
      end

      def perform_deletes
        target_deletes = Dir.glob("#{hourlies_directory}/**/*_deletes_*.txt")

        processed_deletes = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_process = target_deletes - processed_deletes

        indexer.logger.info "Found #{files_to_process.length} files to process for deletes"

        files_to_process.each do |file_name|
          File
            .read(file_name)
            .split("\n")
            .map { |id| delete(id) }
          redis.set("hr:#{file_name}", true)
        end
      end

      def delete(id)
        indexer.writer.delete(id)
        indexer.logger.info "Deleted ID #{id}"
      end

      def perform_indexes
        target_files = Dir.glob("#{hourlies_directory}/**/*.m*rc")

        indexed_files = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_index = target_files - indexed_files

        indexer.logger.info "Found #{files_to_index.length} files to index"
        array_of_files = files_to_index.map { |file| File.new(file) }

        indexer.process array_of_files

        files_to_index.each do |file_name|
          indexer.logger.info "marking #{file_name} as done"
          redis.set("hr:#{file_name}", true)
        end
      end
    end
  end
end
