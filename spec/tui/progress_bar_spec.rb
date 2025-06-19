require 'spec_helper'

RSpec.describe Nylera::TUI::ProgressBar do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::ProgressBar
      include Nylera::TUI::Utils
      include Curses
      
      attr_accessor :total_duration, :elapsed_time, :elapsed_mutex
      
      def initialize
        @total_duration = 180.0
        @elapsed_time = { seconds: 45.0 }
        @elapsed_mutex = Mutex.new
        @call_log = []
      end
      
      def setpos(y, x); @call_log << [:setpos, y, x]; end
      def addstr(str); @call_log << [:addstr, str]; end
      def attron(color); yield if block_given?; end
      def color_pair(n); n; end
      
      def added_string?(pattern)
        @call_log.any? { |call| call[0] == :addstr && call[1].to_s.match?(pattern) }
      end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#draw_progress_bar' do
    it 'draws time display' do
      instance.draw_progress_bar(0, 0, 40, 1)
      expect(instance.added_string?(/00:45.*03:00/)).to be true
    end

    it 'draws progress fill' do
      instance.draw_progress_bar(0, 0, 40, 1)
      expect(instance.added_string?(/━/)).to be true
    end
  end
end
