# frozen_string_literal: true

module PsulibTraject
  module Workers
    class HourlyIndexer < Base
      def perform
        target = Dir.glob("#{ConfigSettings.symphony_data_path}/#{ConfigSettings.symphony_hourlies_subdir}/**/*.mrc")
        indexed_files = redis.keys('hr:*').map! { |e| e.gsub('hr:', '') }
        files_to_index = target - indexed_files

        files_to_index.each do |t|
          puts "indexing #{t}"
          PsulibTraject::IndexFileWorker.perform_async(t)
          redis.set("hr:#{t}", true)
        end
      end
    end
  end
end
