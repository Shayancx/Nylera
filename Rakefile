require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run tests with coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].invoke
end

desc "Run performance tests"
task :perf do
  ENV['NYLERA_PERF'] = '1'
  ruby 'bin/nylera.rb'
end

desc "Check code style"
task :lint do
  sh 'bundle exec rubocop lib/ spec/'
end

desc "Run all quality checks"
task :quality => [:spec, :lint, :coverage]

desc "Run all quality checks"
task :quality => [:spec, :lint, :coverage]

desc "Generate YARD documentation"
task :docs do
  sh 'yard doc --output-dir doc/api'
end

desc "Run performance benchmarks"
task :benchmark do
  sh 'bundle exec rspec --tag performance'
end

desc "Profile memory usage"
task :profile_memory do
  require 'memory_profiler'
  report = MemoryProfiler.report do
    load 'bin/nylera.rb'
  end
  report.pretty_print(to_file: 'tmp/memory_profile.txt')
end

desc "Check for security vulnerabilities"
task :security do
  sh 'bundle exec bundle-audit check --update'
end
