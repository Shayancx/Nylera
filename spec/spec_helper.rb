# Only load SimpleCov if explicitly requested
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
end

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

# Set test environment
ENV['RACK_ENV'] = 'test'

# Require all library files
Dir[File.join(__dir__, '../lib/**/*.rb')].sort.each do |f|
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

  # Set a timeout for specs to prevent freezing
  config.around(:each) do |example|
    Timeout.timeout(5) do
      example.run
    end
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = false  # Reduce noise
  
  config.order = :random
  Kernel.srand config.seed
  
  # Skip tests that require actual audio hardware in CI environments
  config.filter_run_excluding :requires_audio_hardware if ENV['CI']
  
  # Skip performance tests by default
  config.filter_run_excluding :performance unless ENV['PERF_TEST']
end
