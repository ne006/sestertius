# frozen_string_literal: true

RSpec.describe Sestertius::Service::KeyRateDelta do
  subject(:service) { described_class.new(**params) }

  let(:key_rate_history) { [] }

  before do
    cbr_api = instance_double(CBR::API)

    allow(CBR::API).to receive(:new).and_return(cbr_api)
    allow(cbr_api).to receive(:key_rate).and_return(key_rate_history)
  end

  describe '#initialize' do
    context 'with valid params' do
      context 'with empty params' do
        let(:params) { {} }

        it 'uses delta of 1.0' do
          expect(service.delta).to eq(1.0)
        end

        it 'uses period from 7 days ago to today' do
          expect(service.period).to eq((Date.today - 7)..Date.today)
        end
      end

      context 'with a Numeric delta' do
        let(:params) { { delta: 1 } }

        it 'converts delta to a Float' do
          expect(service.delta).to be_a(Float)
        end
      end

      context 'with Integer period' do
        let(:params) { { period: 3 } }

        it 'uses period from :period days ago to today' do
          expect(service.period).to eq((Date.today - params[:period])..Date.today)
        end
      end

      context 'with Integer Range period' do
        let(:params) { { period: 5..2 } }

        it 'uses period from :period\'s start days ago to :period\'s end days ago' do
          expect(service.period).to eq((Date.today - params[:period].begin)..(Date.today - params[:period].end))
        end
      end

      context 'with Date Range period' do
        let(:params) { { period: (Date.today - 15)..(Date.today - 8) } }

        it 'uses provided period' do
          expect(service.period).to eq(params[:period])
        end
      end
    end

    context 'with invalid params' do
      context 'with non-Numeric delta' do
        let(:params) { { delta: 'delta' } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'delta should be a Numeric')
        end
      end

      context 'with infinite delta' do
        let(:params) { { delta: Float::INFINITY } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'delta should be finite')
        end
      end

      context 'with negative delta' do
        let(:params) { { delta: -5 } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'delta should not be negative')
        end
      end

      context 'with non-Integer non-Range period' do
        let(:params) { { period: 5.0 } }

        it 'raises ArgumentError' do
          expect do
            service
          end.to raise_error(ArgumentError, 'period should be an Integer, a Date Range or an Integer Range')
        end
      end

      context 'with non-positive non-Range period' do
        let(:params) { { period: -5 } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'period should be positive')
        end
      end

      context 'with non-Integer Range period' do
        let(:params) { { period: 5.0..2.0 } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'period should be a Date or Integer Range')
        end
      end

      context 'with negative ends Range period' do
        let(:params) { { period: -5..2 } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'period should have non-negative ends')
        end
      end

      context 'with ascending Range period' do
        let(:params) { { period: 2..5 } }

        it 'raises ArgumentError' do
          expect { service }.to raise_error(ArgumentError, 'period should be descending')
        end
      end
    end
  end

  describe '#call' do
    subject(:call) { service.call }

    context 'when key rate history is 2 or more elements long' do
      let(:key_rate_history) do
        [
          CBR::API::KeyRate.new(Date.new(2024, 2, 1), 15.0),
          CBR::API::KeyRate.new(Date.new(2024, 2, 2), 15.0),
          CBR::API::KeyRate.new(Date.new(2024, 2, 3), 15.0),
          CBR::API::KeyRate.new(Date.new(2024, 2, 4), 15.0),
          CBR::API::KeyRate.new(Date.new(2024, 2, 5), 25.0),
          CBR::API::KeyRate.new(Date.new(2024, 2, 6), 20.0)
        ]
      end

      context 'when actual delta on the ends of period is greater then or equal to delta' do
        let(:params) { { delta: 5 } }

        it 'returns result with pass = true' do
          expect(call).to include(
            delta: 5.0, actual_delta: 5.0, pass: true, rate: key_rate_history.last.rate,
            period: key_rate_history.first.date..key_rate_history.last.date
          )
        end
      end

      context 'when actual delta on the ends of period is less then delta' do
        let(:params) { { delta: 10 } }

        it 'returns result with pass = true' do
          expect(call).to include(
            delta: 10.0, actual_delta: 5.0, pass: false, rate: key_rate_history.last.rate,
            period: key_rate_history.first.date..key_rate_history.last.date
          )
        end
      end
    end

    context 'when key rate data request fails' do
      let(:params) { { delta: 5 } }
      let(:key_rate_history) { false }

      it 'raise error' do
        expect { call }.to raise_error('Could not fetch key rate data')
      end
    end

    context 'when key rate data is empty' do
      let(:params) { { delta: 5 } }
      let(:key_rate_history) { [] }

      it 'raise error' do
        expect { call }.to raise_error('Could not fetch key rate data')
      end
    end
  end
end
