# frozen_string_literal: true

module PsulibTraject
  module Workers
    class HourlyIndexer < Base
      def perform
        target = Dir.glob("#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*.m*rc")
        indexed_files = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_index = target - indexed_files

        files_to_index.each do |t|
          PsulibTraject::Workers::Indexer.perform_now(t)
          redis.set("hr:#{t}", true)
        end

        deletes = Dir.glob("#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*_deletes_*.txt")
        processed_deletes = redis.keys('hr:*').map { |e| e.gsub('hr:', '') }
        files_to_process = deletes - processed_deletes

        files_to_process.each do |f|
          PsulibTraject::Workers::Deleter.perform_now(f)
          redis.set("hr:#{f}", true)
        end
      end
    end
  end
end
