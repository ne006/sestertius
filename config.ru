# frozen_string_literal: true

require_relative 'zeitwerk'

require 'rack/common_logger'

use Rack::CommonLogger

Sestertius::API.compile!

run Sestertius::API
