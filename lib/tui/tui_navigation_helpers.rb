# frozen_string_literal: true

module Nylera
  module TUI
    # TuiNavigationHelpers extracts viewport logic from MainTui
    module TuiNavigationHelpers
      private

      def move_selection_up
        @mutex.synchronize do
          if @current_selection.positive?
            @current_selection -= 1
            adjust_viewport
          end
        end
      end

      def move_selection_down
        @mutex.synchronize do
          if @current_selection < @filtered_playlist.size - 1
            @current_selection += 1
            adjust_viewport
          end
        end
      end

      def adjust_viewport
        nav_inner_height = @nav_box_height - 2
        nav_inner_height -= 1 if @search_mode
        nav_inner_height = 0 if nav_inner_height.negative?

        if @current_selection < @start_index
          @start_index = @current_selection
        elsif @current_selection >= (@start_index + nav_inner_height)
          @start_index = @current_selection - nav_inner_height + 1
        end
        @start_index = 0 if @start_index.negative?
      end
    end
  end
end
