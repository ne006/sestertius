# frozen_string_literal: true

require 'rack/test'

RSpec.describe Sestertius::API, type: :api do
  include Rack::Test::Methods

  def app
    described_class
  end

  describe 'api/v1' do
    describe '/key_rate' do
      describe '/delta' do
        let!(:krd_service) do
          krd_service = instance_double(Sestertius::Service::KeyRateDelta)

          allow(Sestertius::Service::KeyRateDelta).to receive(:new).and_return(krd_service)
          allow(krd_service).to receive(:call).and_return(krd_result)

          krd_service
        end

        let(:krd_result) do
          {
            delta: params.fetch(:delta, 1.0),
            actual_delta: 2.3,
            period: params.fetch(:period, 7).then do |period|
              case period
              in Integer then (Date.today - period)..(Date.today)
              in [Integer, Integer] then (Date.today - period.first)..(Date.today - period.last)
              in [Date, Date] then period.first..period.last
              else (Date.today - 7)..(Date.today)
              end
            end,
            rate: 5.6
          }.then do |result|
            result.merge(pass: result[:delta] <= result[:actual_delta])
          rescue StandardError
            result.merge(pass: false)
          end
        end

        let(:request) { get('/api/v1/key_rate/delta', params) }

        shared_examples('key_rate/delta sucessful') do
          it 'returns 200' do
            request

            expect(last_response).to be_ok
          end

          it 'returns data' do
            request

            expect(last_response_json).to eq(JSON.parse(JSON.generate(krd_result)))
          end

          it 'instantiates KeyRateData with params' do
            request

            expect(Sestertius::Service::KeyRateDelta).to have_received(:new).with(params.empty? ? no_args : params)
          end

          it 'calls KeyRateData instance' do
            request

            expect(krd_service).to have_received(:call)
          end
        end

        context 'without params' do
          let(:params) { {} }

          include_examples 'key_rate/delta sucessful'
        end

        context 'with delta' do
          let(:params) { { delta: 3.0 } }

          include_examples 'key_rate/delta sucessful'
        end

        context 'with Integer period' do
          let(:params) { { period: 4 } }

          include_examples 'key_rate/delta sucessful'
        end

        context 'with Integer Range period' do
          let(:params) { { period: [5, 3] } }

          include_examples 'key_rate/delta sucessful'
        end

        context 'with Date Range period' do
          let(:params) { { period: [Date.today - 7, Date.today - 4] } }

          include_examples 'key_rate/delta sucessful'
        end

        context 'with invalid delta' do
          let(:params) { { delta: 'a13' } }

          it 'returns 400' do
            request

            expect(last_response.status).to eq(400)
          end

          it 'returns error' do
            request

            expect(last_response_json).to eq({ 'error' => 'delta is invalid' })
          end
        end

        context 'with invalid period' do
          let(:params) { { period: %w[a 13d] } }

          it 'returns 400' do
            request

            expect(last_response.status).to eq(400)
          end

          it 'returns error' do
            request

            expect(last_response_json).to eq({ 'error' => 'period is invalid' })
          end
        end
      end
    end
  end
end
