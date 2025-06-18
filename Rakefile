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
