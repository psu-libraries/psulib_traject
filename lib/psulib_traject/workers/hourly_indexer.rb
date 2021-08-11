# frozen_string_literal: true

module PsulibTraject
  module Workers
    class HourlyIndexer < Base
      def perform
        target = Dir.glob(
          "#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*.m*rc"
        )
        indexed_files = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_index = target - indexed_files

        indexer.logger.info "Found #{files_to_index.length} files to index"
        array_of_files = files_to_index.map { |file| File.new(file) }

        indexer.process array_of_files

        files_to_index.each do |t|
          indexer.logger.info "marking #{t} as done"
          redis.set("hr:#{t}", true)
        end

        deletes = Dir.glob(
          "#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*_deletes_*.txt"
        )
        processed_deletes = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_process = deletes - processed_deletes

        indexer.logger.info "Found #{files_to_process.length} files to process for deletes"

        files_to_process.each do |file_name|
          File.open(file_name, 'r') do |f|
            f.each_line do |line|
              id = line.chomp
              indexer.writer.delete(id)
              indexer.logger.info "Deleted ID #{id}"
            end
          end
          redis.set("hr:#{file_name}", true)
        end
      end
    end
  end
end
