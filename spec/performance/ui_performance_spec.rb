require 'spec_helper'

RSpec.describe 'UI Performance', :performance do
  let(:dummy_tui) do
    Class.new do
      include Nylera::TUI::NavigationBox
      include Nylera::TUI::InfoBox
      include Nylera::TUI::BoxDrawer
      include Nylera::TUI::Utils
      include Curses
      
      attr_accessor :filtered_playlist, :current_selection, :start_index
      attr_accessor :song_name_str, :artist_str, :album_str, :genre_str
      attr_accessor :total_duration, :elapsed_time, :elapsed_mutex
      
      def initialize
        @filtered_playlist = Array.new(1000) { |i| "song#{i}.mp3" }
        @current_selection = 0
        @start_index = 0
        @song_name_str = "Test Song"
        @artist_str = "Test Artist"
        @album_str = "Test Album"
        @genre_str = "Rock"
        @total_duration = 180.0
        @elapsed_time = { seconds: 45.0 }
        @elapsed_mutex = Mutex.new
      end
      
      # Mock Curses methods
      def setpos(y, x); end
      def addstr(str); end
      def attron(color); yield if block_given?; end
      def attroff(color); end
      def color_pair(n); n; end
      def lines; 24; end
      def cols; 80; end
      def refresh; end
      def safe_utf8_copy(str); str || ''; end
      def current_elapsed; @elapsed_time[:seconds]; end
      def format_time(s); "00:00"; end
    end.new
  end

  it 'renders navigation box quickly' do
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    100.times { dummy_tui.draw_nav_box(0, 0, 40, 20) }
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    elapsed = end_time - start_time
    expect(elapsed).to be < 0.1 # Should render 100 times in less than 100ms
  end

  it 'handles large playlists efficiently' do
    dummy_tui.filtered_playlist = Array.new(10000) { |i| "song#{i}.mp3" }
    
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    dummy_tui.draw_playlist_contents(0, 0, 40, 20)
    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    
    elapsed = end_time - start_time
    expect(elapsed).to be < 0.01 # Should render in less than 10ms
  end
end
