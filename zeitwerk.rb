# frozen_string_literal: true

require 'zeitwerk'

loader = Zeitwerk::Loader.new

loader.inflector.inflect(
  'api' => 'API',
  'cbr' => 'CBR'
)

loader.push_dir('./app')
loader.push_dir('./lib')

loader.setup

Zeitwerk::Loader::CURRENT = loader
