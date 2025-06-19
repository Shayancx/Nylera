# frozen_string_literal: true

module Nylera
  module TUI
    # TuiLoopHelpers extracts main_loop logic + refresh/exit to reduce MainTui size
    # PERFORMANCE FIX: Removed full screen clear to prevent flickering
    module TuiLoopHelpers
      private

      def main_loop
        @last_drawn_content = {}
        loop do
          @mutex.synchronize { @status = @status_provider.call }
          refresh_display

          user_input = getch
          handle_input(user_input) { |act| yield(act) if block_given? } if user_input
        end
      end

      def refresh_display
        # PERFORMANCE FIX: Only update changed areas instead of clearing entire screen
        @nav_box_height = lines - Nylera::Constants::INFO_BOX_HEIGHT
        @nav_box_height = 1 if @nav_box_height < 1

        # Only redraw if terminal size changed
        if @last_lines != lines || @last_cols != cols
          clear
          @last_lines = lines
          @last_cols = cols
        end

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

      # Helper to check if content changed
      def content_changed?(key, new_content)
        old_content = @last_drawn_content[key]
        return true if old_content != new_content
        @last_drawn_content[key] = new_content
        false
      end
    end
  end
end

      def exit_application
        clear
        refresh
        close_screen
        exit
      end
