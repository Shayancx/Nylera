# frozen_string_literal: true

module Nylera
  module TUI
    # Handles the search mode logic (typing, filtering, etc.)
    module SearchHandler
      def process_search_input(input_key, &block)
        return if handle_esc_enter(input_key, &block)
        return handle_backspace if backspace_key?(input_key)

        handle_general_search_key(input_key, &block)
      end

      def enter_search_mode
        @search_mode   = true
        @search_query  = String.new
        apply_search_filter
      end

      def exit_search_mode
        @search_mode       = false
        @search_query      = String.new
        @filtered_playlist = @playlist.dup
        @current_selection = 0
        @start_index       = 0
      end

      private

      def handle_esc_enter(input_key)
        return handle_esc if input_key == 27 # ESC
        return handle_enter_key { |a| yield(a) if block_given? } if [10, 13].include?(input_key)

        false
      end

      def handle_esc
        exit_search_mode
        true
      end

      def handle_enter_key
        yield(@current_selection) if block_given?
        exit_search_mode
        true
      end

      def backspace_key?(input_key)
        [127, Curses::Key::BACKSPACE].include?(input_key)
      end

      def handle_backspace
        @search_query.chop! unless @search_query.empty?
        apply_search_filter
      end

      def handle_general_search_key(input_key)
        if printable_char?(input_key)
          @search_query << input_key
          apply_search_filter
        end
        move_selection_up   if input_key == Curses::Key::UP
        move_selection_down if input_key == Curses::Key::DOWN
      end

      def printable_char?(input_key)
        input_key.is_a?(String) && input_key =~ /[[:print:]]/
      end

      def apply_search_filter
        query_down = @search_query.downcase
        @filtered_playlist = @playlist.select do |path|
          base = File.basename(path, File.extname(path)).downcase
          base.start_with?(query_down)
        end
        @current_selection = 0
        @start_index       = 0
      end
    end
  end
end
