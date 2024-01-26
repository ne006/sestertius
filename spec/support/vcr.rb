require 'vcr'
require 'webmock'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  config.hook_into :webmock
end

RSpec.configure do |config|
  config.around :each, vcr_cassette: ->(value) { value.is_a?(String) } do |example|
    VCR.use_cassette(example.metadata[:vcr_cassette], record: :new_episodes) do |_c|
      example.run
    end
  end
end