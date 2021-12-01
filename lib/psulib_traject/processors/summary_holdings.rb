# frozen_string_literal: true

module PsulibTraject
  module Processors
    class SummaryHoldings
      # @param [Marc::Record]
      # @return [Hash]
      def self.call(record:)
        new(record).build
      end

      def initialize(record)
        @record = record
        freeze
      end

      def build
        {}.tap do |data|
          units.map do |unit|
            data[unit.library] ||= {}
            data[unit.library][unit.location] ||= []
            data[unit.library][unit.location] << unit.summary_data
          end
        end
      end

      private

        attr_reader :record

        def units
          [].tap do |collection|
            unit = PeriodicalHoldings.new
            record.fields(PeriodicalHoldings.tags.values).map do |field|
              case field.tag
              when PeriodicalHoldings.tags[:heading]
                if unit.in_use?
                  collection << unit
                  unit = PeriodicalHoldings.new
                end
                unit.heading = field
              when PeriodicalHoldings.tags[:summary]
                unit.add_summary(field)
              when PeriodicalHoldings.tags[:supplemental]
                unit.add_supplement(field)
              when PeriodicalHoldings.tags[:index]
                unit.add_index(field)
              end
            end
            collection << unit if unit.in_use?
          end
        end
    end
  end
end
