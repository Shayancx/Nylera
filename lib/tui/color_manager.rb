# frozen_string_literal: true

require 'curses'

module Nylera
  module TUI
    # Handles curses color setup
    module ColorManager
      include Curses

      def setup_colors
        return unless color_setup_allowed?

        define_custom_colors
        start_color
        setup_color_pairs
      end

      private

      def color_setup_allowed?
        can_change_color? && has_colors?
      end

      def define_custom_colors
        # Example color definitions (teal, gray, etc.)
        init_color(37,  (28.0 / 255 * 1000).to_i,  (141.0 / 255 * 1000).to_i, (119.0 / 255 * 1000).to_i)
        init_color(244, (77.0 / 255 * 1000).to_i,  (77.0 / 255 * 1000).to_i,  (77.0 / 255 * 1000).to_i)
        init_color(61,  835, 0, 435) # #D5006F => 835,0,435
      end

      def setup_color_pairs
        init_pair(1, 198, COLOR_BLACK) # progress fill => Ruby color
        init_pair(2, COLOR_WHITE, COLOR_BLACK)
        init_pair(3, COLOR_BLACK, 37)  # highlight => black on teal
        init_pair(4, 37, COLOR_BLACK)  # border => teal
        init_pair(5, 244, COLOR_BLACK) # empty => #4d4d4d
      end
    end
  end
end
