# frozen_string_literal: true

module Nylera
  # Performance monitoring for debugging and optimization
  class PerformanceMonitor
    def initialize
      @metrics = {}
      @enabled = ENV['NYLERA_PERF'] == '1'
    end

    def measure(name)
      return yield unless @enabled

      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      
      @metrics[name] ||= []
      @metrics[name] << elapsed
      
      result
    end

    def report
      return unless @enabled

      @metrics.each do |name, times|
        avg = times.sum / times.size
        puts "#{name}: avg=#{(avg * 1000).round(2)}ms, calls=#{times.size}"
      end
    end
  end
end
