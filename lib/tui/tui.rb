# frozen_string_literal: true

require 'curses'
require_relative '../constants'
require_relative 'color_manager'
require_relative 'box_drawer'
require_relative 'navigation_box'
require_relative 'info_box'
require_relative 'progress_bar'
require_relative 'input_handler'
require_relative 'search_handler'
require_relative 'utils'
require_relative 'tui_loop_helpers'
require_relative 'tui_navigation_helpers'

module Nylera
  module TUI
    # MainTui orchestrates the overall flow, includes multiple modules
    class MainTui
      include Curses
      include ColorManager
      include BoxDrawer
      include NavigationBox
      include InfoBox
      include ProgressBar
      include InputHandler
      include SearchHandler
      include Utils
      include TuiLoopHelpers
      include TuiNavigationHelpers

      attr_reader :filtered_playlist

      def initialize(playlist, elapsed_time, elapsed_mutex, status_provider)
        store_init_args(playlist, elapsed_time, elapsed_mutex, status_provider)
        basic_init_setup
      end

      def start
        prepare_curses_screen
        main_loop { |action| yield(action) if block_given? }
      ensure
        close_screen
      end

      def update(selection, new_status, now_playing, total_dur = 0.0)
        @mutex.synchronize do
          @current_selection = selection
          @status            = new_status
          @total_duration    = total_dur if total_dur.positive?
          @song_name_str     = now_playing unless now_playing.nil?
        end
      end

      private

      def store_init_args(playlist, elapsed_time, elapsed_mutex, status_provider)
        @playlist          = playlist
        @filtered_playlist = playlist.dup
        @elapsed_time      = elapsed_time
        @elapsed_mutex     = elapsed_mutex
        @status_provider   = status_provider
      end

      def basic_init_setup
        init_selection
        init_metadata_strings
        init_flags_and_mutex
      end

      def init_selection
        @current_selection = 0
        @start_index       = 0
        @status            = 'Stopped'
      end

      def init_metadata_strings
        @song_name_str = 'Unknown'
        @artist_str    = 'Unknown'
        @album_str     = 'Unknown'
        @genre_str     = 'Unknown'
      end

      def init_flags_and_mutex
        @mutex          = Mutex.new
        @total_duration = 0.0
        @nav_box_height = 0
        @last_key       = nil
        @last_key_time  = Time.now
        @search_mode    = false
        @search_query   = String.new
        @colon_pressed  = false
      end

      def prepare_curses_screen
        init_screen
        setup_colors
        noecho
        cbreak
        stdscr.keypad(true)
        curs_set(0)
        refresh
        Curses.timeout = 20
      end
    end
  end
end
