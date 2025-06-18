# frozen_string_literal: true

module Nylera
  module TUI
    # Module for displaying errors in the TUI
    module ErrorDisplay
      def display_error(error_msg)
        # Store error for display
        @error_message = error_msg
        @error_display_time = Time.now
      end

      def draw_error_if_needed
        return unless @error_message
        return if Time.now - @error_display_time > 5 # Show error for 5 seconds

        # Draw error in the middle of the info box
        error_y = @nav_box_height + 2
        error_x = 2
        
        setpos(error_y, error_x)
        attron(color_pair(1)) do  # Use red color
          addstr("Error: #{@error_message}"[0...(cols - 4)])
        end
      end

      def clear_error
        @error_message = nil
      end
    end
  end
end
