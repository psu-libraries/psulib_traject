# frozen_string_literal: true

module PsulibTraject
  module Workers
    class Base
      include Sidekiq::Worker

      def self.perform_now(*args)
        new.perform(*args)
      end

      def redis
        @redis ||= Redis.new
      end
    end
  end
end
