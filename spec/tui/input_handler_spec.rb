require 'spec_helper'

RSpec.describe Nylera::TUI::InputHandler do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::InputHandler
      include Curses
      
      attr_accessor :search_mode, :colon_pressed, :current_selection
      attr_accessor :last_key, :last_key_time
      
      def initialize
        @search_mode = false
        @colon_pressed = false
        @current_selection = 0
        @last_key = nil
        @last_key_time = Time.now
      end
      
      def process_search_input(key); end
      def enter_search_mode; end
      def move_selection_up; end
      def move_selection_down; end
      def exit_application; exit; end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#handle_input' do
    it 'handles space for pause/resume' do
      expect { |b| instance.handle_input(' ', &b) }.to yield_with_args(:pause_resume)
    end

    it 'handles enter for track selection' do
      instance.current_selection = 5
      expect { |b| instance.handle_input(10, &b) }.to yield_with_args(5)
    end

    it 'handles q for quit' do
      expect(instance).to receive(:exit_application)
      instance.handle_input('q')
    end

    it 'handles arrow keys for navigation' do
      expect(instance).to receive(:move_selection_up)
      instance.handle_input(Curses::Key::UP)
      
      expect(instance).to receive(:move_selection_down)
      instance.handle_input(Curses::Key::DOWN)
    end

    it 'handles double-tap for skip' do
      instance.last_key = Curses::Key::RIGHT
      instance.last_key_time = Time.now
      expect { |b| instance.handle_input(Curses::Key::RIGHT, &b) }.to yield_with_args(:ff_10sec)
    end
  end

  describe '#process_colon_input' do
    it 'enters search mode on :S' do
      instance.colon_pressed = true
      expect(instance).to receive(:enter_search_mode)
      instance.handle_input('S')
    end
  end
end
