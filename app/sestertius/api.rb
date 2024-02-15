# frozen_string_literal: true

require 'grape'

module Sestertius
  class API < Grape::API
    version 'v1', vendor: 'sestertius'
    format :json
    prefix :api

    resource :key_rate do
      desc 'Get key rate delta from https://cbr.ru for a period'
      params do
        optional :delta, type: Float, desc: 'delta between rates which triggers check pass'
        optional :period, types: [Integer, [Integer], [Date]], desc: 'period to check key rate value on'
      end
      get :delta do
        Service::KeyRateDelta.new(**params.slice(:delta, :period).symbolize_keys).call
      end
    end
  end
end
