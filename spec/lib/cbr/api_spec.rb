# frozen_string_literal: true

require 'faraday'

RSpec.describe CBR::API, vcr_cassette: 'cbr', vcr_config: { match_requests_on: %i[uri body] } do
  before { allow(Date).to receive(:today).and_return(Date.new(2024, 2, 5)) }

  describe '#key_rate' do
    let(:result) { described_class.new.key_rate(**params) }

    context 'with default arguments' do
      let(:params) { {} }

      it 'returns key rate history' do
        expect(result).to all(have_attributes(date: a_kind_of(Date), rate: a_kind_of(Numeric)))
      end
    end

    context 'with arguments' do
      let(:params) { { from: Date.today - 10, to: Date.today } }

      it 'returns key rate history' do
        expect(result).to all(have_attributes(date: a_kind_of(Date), rate: a_kind_of(Numeric)))
      end
    end
  end
end
