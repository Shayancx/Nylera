# frozen_string_literal: true

module Nylera
  module TUI
    # Optimized refresh logic to improve responsiveness
    module OptimizedRefresh
      def setup_dirty_tracking
        @dirty_tracker = DirtyTracker.new
        @last_status = nil
        @last_elapsed = -1
        @last_selection = -1
        @last_search_query = nil
        @redraw_countdown = 0
      end

      def check_for_changes
        # Check if terminal was resized
        if @last_lines != lines || @last_cols != cols
          @dirty_tracker.mark_all_dirty
          clear # Only clear on resize
          @last_lines = lines
          @last_cols = cols
        end

        # Check status changes
        current_status = @mutex.synchronize { @status }
        if current_status != @last_status
          @dirty_tracker.mark_dirty(:info_box)
          @last_status = current_status
        end

        # Check elapsed time changes (only update if changed by >= 1 second)
        current_elapsed = current_elapsed().to_i
        if current_elapsed != @last_elapsed
          @last_elapsed = current_elapsed
          @dirty_tracker.mark_dirty(:progress_bar)
        end

        # Check selection changes
        if @current_selection != @last_selection
          @dirty_tracker.mark_dirty(:playlist)
          @last_selection = @current_selection
        end

        # Check search query changes
        if @search_query != @last_search_query
          @dirty_tracker.mark_dirty(:search_bar)
          @dirty_tracker.mark_dirty(:playlist)
          @last_search_query = @search_query.dup
        end
        
        # Force periodic full redraw to catch any missed updates
        @redraw_countdown -= 1
        if @redraw_countdown <= 0
          @dirty_tracker.mark_dirty(:nav_box)
          @dirty_tracker.mark_dirty(:info_box)
          @redraw_countdown = 50  # Every ~1 second at 50Hz
        end
      end

      def optimized_refresh_display
        check_for_changes

        # Always redraw if anything is dirty
        if @dirty_tracker.dirty?(:nav_box) || @dirty_tracker.dirty?(:playlist) || @dirty_tracker.dirty?(:search_bar)
          draw_nav_box(0, 0, Nylera::Constants::NAV_BOX_WIDTH, @nav_box_height)
          @dirty_tracker.clear_dirty(:nav_box)
          @dirty_tracker.clear_dirty(:playlist)
          @dirty_tracker.clear_dirty(:search_bar)
        end

        if @dirty_tracker.dirty?(:info_box) || @dirty_tracker.dirty?(:progress_bar)
          draw_info_box(@nav_box_height, 0, cols, Nylera::Constants::INFO_BOX_HEIGHT)
          @dirty_tracker.clear_dirty(:info_box)
          @dirty_tracker.clear_dirty(:progress_bar)
        end

        refresh
      end
    end
  end
end
