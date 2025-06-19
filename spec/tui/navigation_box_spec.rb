require 'spec_helper'

RSpec.describe Nylera::TUI::NavigationBox do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::NavigationBox
      include Nylera::TUI::BoxDrawer
      include Curses
      
      attr_accessor :search_mode, :search_query, :filtered_playlist, :start_index, :current_selection
      
      def initialize
        @search_mode = false
        @search_query = ""
        @filtered_playlist = []
        @start_index = 0
        @current_selection = 0
        @call_log = []
      end
      
      # Mock Curses methods and track calls
      def setpos(y, x); @call_log << [:setpos, y, x]; end
      def addstr(str); @call_log << [:addstr, str]; end
      def attron(color); yield if block_given?; end
      def attroff(color); end
      def color_pair(n); n; end
      def lines; 24; end
      def cols; 80; end
      def safe_utf8_copy(str); str || ''; end
      
      # Helper to check if string was added
      def added_string?(pattern)
        @call_log.any? { |call| call[0] == :addstr && call[1].match?(pattern) }
      end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#draw_nav_box' do
    it 'draws navigation box with frame' do
      expect(instance).to receive(:draw_box_frame).with(0, 0, 40, 20, 4)
      instance.draw_nav_box(0, 0, 40, 20)
    end

    it 'handles minimum height' do
      expect(instance).not_to receive(:draw_box_frame)
      instance.draw_nav_box(0, 0, 40, 1)
    end
  end

  describe '#draw_search_bar' do
    before { instance.search_query = "test" }

    it 'draws search prompt' do
      instance.draw_search_bar(0, 0, 40)
      expect(instance.added_string?(/Search: test/)).to be true
    end

    it 'truncates long search queries' do
      instance.search_query = "a" * 50
      instance.draw_search_bar(0, 0, 20)
      expect(instance.added_string?(/\.\.\./)).to be true
    end
  end

  describe '#draw_playlist_contents' do
    before do
      instance.filtered_playlist = ['song1.mp3', 'song2.mp3', 'song3.mp3']
      instance.current_selection = 1
    end

    it 'draws visible tracks' do
      instance.draw_playlist_contents(0, 0, 40, 3)
      expect(instance.added_string?(/song1/)).to be true
      expect(instance.added_string?(/song2/)).to be true
      expect(instance.added_string?(/song3/)).to be true
    end

    it 'shows message for empty playlist' do
      instance.filtered_playlist = []
      instance.draw_playlist_contents(0, 0, 40, 3)
      expect(instance.added_string?(/No songs found/)).to be true
    end
  end
end
