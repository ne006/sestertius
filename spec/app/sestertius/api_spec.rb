# frozen_string_literal: true

require 'rack/test'

RSpec.describe Sestertius::API, type: :api do
  include Rack::Test::Methods

  def app
    described_class
  end

  describe 'api/v1' do
  end
end
