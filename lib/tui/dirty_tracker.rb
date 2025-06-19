# frozen_string_literal: true

module Nylera
  module TUI
    # Tracks which UI regions need redrawing to prevent unnecessary updates
    # This solves the flickering issue by only redrawing changed content
    class DirtyTracker
      def initialize
        @dirty_regions = {}
        @content_cache = {}
      end

      # Mark a region as dirty (needs redraw)
      def mark_dirty(region)
        @dirty_regions[region] = true
      end

      # Check if region needs redraw
      def dirty?(region)
        @dirty_regions[region] || false
      end

      # Check if content has changed
      def content_changed?(region, new_content)
        old_content = @content_cache[region]
        return true if old_content.nil?
        
        changed = old_content != new_content
        @content_cache[region] = new_content if changed
        changed
      end

      # Clear dirty flag after drawing
      def clear_dirty(region)
        @dirty_regions.delete(region)
      end

      # Mark everything dirty (e.g., after resize)
      def mark_all_dirty
        [:nav_box, :info_box, :search_bar, :playlist, :progress_bar].each do |region|
          mark_dirty(region)
        end
      end
    end
  end
end
