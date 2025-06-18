# frozen_string_literal: true

require 'curses'
require_relative '../constants'

module Nylera
  module TUI
    # Deals with user keystrokes and dispatches them
    module InputHandler
      def handle_input(input_key)
        update_key_timing(input_key)

        if @search_mode
          process_search_input(input_key) { |act| yield(act) if block_given? }
        elsif @colon_pressed
          process_colon_input(input_key)
        else
          double_tap = tap_check(input_key)
          process_main_input(input_key, double_tap) { |act| yield(act) if block_given? }
        end
      end

      private

      def update_key_timing(input_key)
        @last_key      = input_key
        @last_key_time = Time.now
      end

      def tap_check(input_key)
        (input_key == @last_key) &&
          ((Time.now - @last_key_time) < Nylera::Constants::DOUBLE_TAP_WINDOW)
      end

      def process_colon_input(input_key)
        enter_search_mode if input_key == 'S'
        @colon_pressed = false
      end

      def process_main_input(input_key, double_tap)
        return if handle_special_key(input_key, double_tap) { |act| yield(act) if block_given? }

        case input_key
        when Curses::Key::UP
          move_selection_up
        when Curses::Key::DOWN
          move_selection_down
        end
      end

      def handle_special_key(input_key, double_tap)
        key_id = identify_special_key(input_key)
        return false unless key_id

        perform_special_key_action(key_id, double_tap) { |act| yield(act) if block_given? }
        true
      end

      def identify_special_key(input_key)
        return :colon if input_key == ':'
        return :right if input_key == Curses::Key::RIGHT
        return :left  if input_key == Curses::Key::LEFT
        return :enter if [10, 13].include?(input_key)
        return :space if input_key == ' '
        return :quit  if %w[q Q].include?(input_key)

        nil
      end

      def perform_special_key_action(key_id, double_tap)
        meth = special_key_methods[key_id]
        return unless meth

        send(meth, double_tap) { |act| yield(act) if block_given? }
      end

      def special_key_methods
        {
          colon: :colon_action,
          right: :right_action,
          left: :left_action,
          enter: :enter_action,
          space: :space_action,
          quit: :quit_action
        }
      end

      def colon_action(_double_tap)
        @colon_pressed = true
      end

      def right_action(double_tap)
        yield(:ff_10sec) if double_tap && block_given?
      end

      def left_action(double_tap)
        yield(:rw_10sec) if double_tap && block_given?
      end

      def enter_action(_double_tap)
        yield(@current_selection) if block_given?
      end

      def space_action(_double_tap)
        yield(:pause_resume) if block_given?
      end

      def quit_action(_double_tap)
        exit_application
      end
    end
  end
end
