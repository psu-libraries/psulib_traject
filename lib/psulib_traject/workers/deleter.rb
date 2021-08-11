# frozen_string_literal: true

module PsulibTraject
  module Workers
    class Deleter < Base
      def perform(file_name)
        indexer = Traject::Indexer::MarcIndexer.new
        indexer.load_config_file('config/traject.rb')

        File.open(file_name, 'r') do |f|
          f.each_line do |line|
            id = line.chomp
            indexer.writer.delete(id)
            indexer.logger.info "Deleted ID #{id}"
          end
        end
      end
    end
  end
end
