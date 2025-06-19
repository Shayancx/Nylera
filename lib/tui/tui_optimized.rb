# frozen_string_literal: true

require 'curses'
require_relative '../constants'
require_relative '../core/configuration'
require_relative 'screen_manager'
require_relative 'dirty_tracker'
require_relative 'color_manager'
require_relative 'box_drawer'
require_relative 'navigation_box'
require_relative 'info_box'
require_relative 'progress_bar'
require_relative 'input_handler'
require_relative 'search_handler'
require_relative 'utils'
require_relative 'tui_navigation_helpers'
require_relative 'tui_loop_helpers'

module Nylera
  module TUI
    # MainTui with proper dirty tracking that doesn't hide content
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
      include TuiNavigationHelpers
      include TuiLoopHelpers

      attr_reader :filtered_playlist

      def initialize(playlist, elapsed_time, elapsed_mutex, status_provider)
        @config = Configuration.instance
        @screen_manager = ScreenManager.new
        
        store_init_args(playlist, elapsed_time, elapsed_mutex, status_provider)
        basic_init_setup
        
        # Initialize tracking variables
        @last_lines = 0
        @last_cols = 0
        @last_drawn_playlist = []
        @last_drawn_selection = -1
        @last_drawn_status = ""
        @last_drawn_elapsed = -1
        @force_redraw = true
      end

      def start
        @screen_manager.with_screen do
          setup_colors
          main_loop { |action| yield(action) if block_given? }
        end
      end

      def update(selection, new_status, now_playing, total_dur = 0.0)
        @mutex.synchronize do
          @current_selection = selection
          @status = new_status
          @total_duration = total_dur if total_dur.positive?
          @song_name_str = now_playing if now_playing
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

      def main_loop
        loop do
          @mutex.synchronize { @status = @status_provider.call }
          
          # Smart refresh that only redraws when needed
          smart_refresh_display

          user_input = getch
          handle_input(user_input) { |act| yield(act) if block_given? } if user_input
        end
      end

      def smart_refresh_display
        # Check if terminal was resized
        if @last_lines != lines || @last_cols != cols || @force_redraw
          clear
          @last_lines = lines
          @last_cols = cols
          @force_redraw = false
          @last_drawn_playlist = []  # Force playlist redraw
          @last_drawn_selection = -1
        end

        @nav_box_height = lines - Nylera::Constants::INFO_BOX_HEIGHT
        @nav_box_height = 1 if @nav_box_height < 1

        # Always draw the navigation box (it handles its own optimization)
        draw_nav_box(0, 0, Nylera::Constants::NAV_BOX_WIDTH, @nav_box_height)
        
        # Always draw the info box (it handles its own optimization)
        draw_info_box(@nav_box_height, 0, cols, Nylera::Constants::INFO_BOX_HEIGHT)
        
        refresh
      end
    end
  end
end
