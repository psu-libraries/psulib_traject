# frozen_string_literal: true

module PsulibTraject
  module Workers
    class Base
      def self.perform_now(*args)
        new.perform(*args)
      end

      def indexer
        @indexer ||= begin
          indexer = Traject::Indexer::MarcIndexer.new
          indexer.load_config_file('config/traject.rb')
          indexer
        end
      end

      def redis
        @redis ||= Redis.new
      end
    end
  end
end
