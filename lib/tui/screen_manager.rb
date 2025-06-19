# frozen_string_literal: true

module Nylera
  module TUI
    # Manages screen initialization and cleanup
    class ScreenManager
      include Curses

      def initialize
        @initialized = false
      end

      def setup
        return if @initialized
        
        init_screen
        noecho
        cbreak
        stdscr.keypad(true)
        curs_set(0)
        Curses.timeout = 20
        @initialized = true
      end

      def teardown
        return unless @initialized
        
        clear
        refresh
        close_screen
        @initialized = false
      end

      def with_screen
        setup
        yield
      ensure
        teardown
      end
    end
  end
end
