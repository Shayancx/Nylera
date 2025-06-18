require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# Mock FFI library loading for tests if libraries not available
begin
  require 'ffi'
rescue LoadError
  puts "Warning: FFI gem not available, some tests may fail"
end

# Require all library files, handling potential load errors
Dir[File.join(__dir__, '../lib/**/*.rb')].each do |f|
  begin
    require f
  rescue LoadError => e
    puts "Warning: Could not load #{f}: #{e.message}"
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
  
  # Skip tests that require actual audio hardware in CI environments
  config.filter_run_excluding :requires_audio_hardware if ENV['CI']
end
