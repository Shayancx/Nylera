require 'spec_helper'

RSpec.describe Nylera::TUI::InfoBox do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::InfoBox
      include Nylera::TUI::BoxDrawer
      include Nylera::TUI::ProgressBar
      include Curses
      
      attr_accessor :song_name_str, :artist_str, :album_str, :genre_str, :status
      attr_accessor :total_duration, :elapsed_time, :elapsed_mutex
      
      def initialize
        @song_name_str = "Test Song"
        @artist_str = "Test Artist"
        @album_str = "Test Album"
        @genre_str = "Rock"
        @status = "Playing"
        @total_duration = 180.0
        @elapsed_time = { seconds: 45.0 }
        @elapsed_mutex = Mutex.new
      end
      
      # Mock methods
      def setpos(y, x); end
      def addstr(str); end
      def attron(color); yield if block_given?; end
      def attroff(color); end
      def color_pair(n); n; end
      def safe_utf8_copy(str); str || ''; end
      def draw_box_frame(y, x, w, h, color); end
      def draw_progress_bar(y, x, w, h); end
      def current_elapsed; @elapsed_time[:seconds]; end
      def draw_error_if_needed; end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#draw_info_box' do
    it 'draws info box with frame' do
      expect(instance).to receive(:draw_box_frame)
      expect(instance).to receive(:draw_info_contents)
      instance.draw_info_box(0, 0, 80, 5)
    end

    it 'handles minimum height' do
      expect(instance).not_to receive(:draw_info_contents)
      instance.draw_info_box(0, 0, 80, 1)
    end
  end

  describe '#draw_info_contents' do
    it 'draws metadata text' do
      expect(instance).to receive(:addstr).with(/Test Song.*Test Artist.*Test Album.*Rock/)
      instance.draw_info_contents(0, 0, 80, 4)
    end

    it 'draws progress bar when height allows' do
      expect(instance).to receive(:draw_progress_bar)
      instance.draw_info_contents(0, 0, 80, 4)
    end
  end
end
