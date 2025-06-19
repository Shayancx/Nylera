require 'spec_helper'

RSpec.describe Nylera::TUI::SearchHandler do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::SearchHandler
      include Curses
      
      attr_accessor :search_mode, :search_query, :playlist, :filtered_playlist
      attr_accessor :current_selection, :start_index
      
      def initialize
        @search_mode = false
        @search_query = ""
        @playlist = ['song1.mp3', 'song2.mp3', 'test.mp3']
        @filtered_playlist = @playlist.dup
        @current_selection = 0
        @start_index = 0
      end
      
      def move_selection_up; end
      def move_selection_down; end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#enter_search_mode' do
    it 'enables search mode' do
      instance.enter_search_mode
      expect(instance.search_mode).to be true
      expect(instance.search_query).to eq("")
    end
  end

  describe '#exit_search_mode' do
    it 'disables search mode and resets' do
      instance.search_mode = true
      instance.search_query = "test"
      instance.exit_search_mode
      
      expect(instance.search_mode).to be false
      expect(instance.search_query).to eq("")
      expect(instance.filtered_playlist).to eq(instance.playlist)
    end
  end

  describe '#apply_search_filter' do
    it 'filters playlist by query' do
      instance.search_query = "test"
      instance.send(:apply_search_filter)
      expect(instance.filtered_playlist).to eq(['test.mp3'])
    end

    it 'is case insensitive' do
      instance.search_query = "TEST"
      instance.send(:apply_search_filter)
      expect(instance.filtered_playlist).to eq(['test.mp3'])
    end
  end

  describe '#process_search_input' do
    it 'handles printable characters' do
      instance.search_mode = true
      expect(instance).to receive(:apply_search_filter)
      instance.process_search_input('a')
      expect(instance.search_query).to eq('a')
    end

    it 'handles backspace' do
      instance.search_mode = true
      instance.search_query = "test"
      instance.process_search_input(127)
      expect(instance.search_query).to eq("tes")
    end

    it 'handles escape to exit' do
      instance.search_mode = true
      instance.process_search_input(27)
      expect(instance.search_mode).to be false
    end
  end
end
