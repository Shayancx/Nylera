# frozen_string_literal: true

module Nylera
  module TUI
    # TuiLoopHelpers extracts main_loop logic + refresh/exit to reduce MainTui size
    module TuiLoopHelpers
      private

      def main_loop
        loop do
          @mutex.synchronize { @status = @status_provider.call }
          refresh_display

          user_input = getch
          handle_input(user_input) { |act| yield(act) if block_given? } if user_input
        end
      end

      def refresh_display
        clear
        @nav_box_height = lines - Nylera::Constants::INFO_BOX_HEIGHT
        @nav_box_height = 1 if @nav_box_height < 1

        draw_nav_box(0, 0, Nylera::Constants::NAV_BOX_WIDTH, @nav_box_height)
        draw_info_box(@nav_box_height, 0, cols, Nylera::Constants::INFO_BOX_HEIGHT)
        refresh
      end

      def exit_application
        clear
        refresh
        close_screen
        exit
      end
    end
  end
end
