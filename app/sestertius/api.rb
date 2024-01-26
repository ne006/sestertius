# frozen_string_literal: true

require 'grape'

module Sestertius
  class API < Grape::API
    version 'v1', vendor: 'sestertius'
    format :json
    prefix :api
  end
end
