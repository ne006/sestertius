# frozen_string_literal: true

require 'date'

module Sestertius
  module Service
    class KeyRateDelta
      attr_reader :delta, :period

      def initialize(delta: 1.0, period: 7)
        @delta = validate_delta(delta).to_f
        @period = form_period(period)
      end

      def call
        raise 'Could not fetch key rate data' unless key_rate_data.is_a?(Array) && key_rate_data.any?

        compare_delta
      end

      private

      def validate_delta(delta)
        raise ArgumentError, 'delta should be a Numeric' unless delta.is_a?(Numeric)
        raise ArgumentError, 'delta should be finite' unless delta.finite?
        raise ArgumentError, 'delta should not be negative' if delta.negative?

        delta
      end

      def form_period(period) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        case period
        when Integer
          raise ArgumentError, 'period should be positive' unless period.positive?

          (Date.today - period)..Date.today
        when Range
          case [period.begin, period.end]
          in [Date, Date] then period
          in [Integer, Integer]
            if period.begin.negative? || period.end.negative?
              raise ArgumentError,
                    'period should have non-negative ends'
            end
            raise ArgumentError, 'period should be descending' unless period.begin > period.end

            (Date.today - period.begin)..(Date.today - period.end)
          else raise ArgumentError, 'period should be a Date or Integer Range'
          end
        else
          raise ArgumentError, 'period should be an Integer, a Date Range or an Integer Range'
        end
      end

      def key_rate_data
        @key_rate_data ||= CBR::API.new.key_rate(from: period.begin, to: period.end)
      end

      def actual_delta
        @actual_delta ||= key_rate_data.last.rate - key_rate_data.first.rate
      end

      def compare_delta
        {
          delta:,
          actual_delta:,
          pass: delta <= actual_delta,
          period: key_rate_data.first.date..key_rate_data.last.date,
          rate: key_rate_data.last.rate
        }
      end
    end
  end
end
