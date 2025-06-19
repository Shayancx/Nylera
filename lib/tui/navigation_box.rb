# frozen_string_literal: true

require_relative 'box_drawer'

module Nylera
  module TUI
    # Draws the left box for playlist navigation
    module NavigationBox
      def draw_nav_box(pos_y, pos_x, box_w, box_h)
        return if box_h < 2

        # Always draw box frame
        draw_box_frame(pos_y, pos_x, box_w, box_h, 4)
        
        offset_top = pos_y + 1
        offset_top += draw_search_bar(offset_top, pos_x + 1, box_w - 2) if @search_mode

        height_avail = (pos_y + box_h - 1) - offset_top
        height_avail = 1 if height_avail < 1

        # Always draw playlist contents
        draw_playlist_contents(offset_top, pos_x + 1, box_w - 2, height_avail)
      end

      def draw_search_bar(pos_y, pos_x, bar_w)
        prepare_search_bar(pos_y, pos_x, bar_w)

        prompt = "Search: #{@search_query}"
        display_str = if prompt.size > bar_w
                        "#{prompt[0...(bar_w - 3)]}..."
                      else
                        prompt
                      end
        addstr(display_str)
        1
      end

      def prepare_search_bar(pos_y, pos_x, bar_w)
        setpos(pos_y, pos_x)
        attron(color_pair(2)) { addstr(' ' * bar_w) }
        setpos(pos_y, pos_x)
      end

      def draw_playlist_contents(pos_y, pos_x, box_w, box_h)
        return if box_h <= 0

        # Clear the area first
        box_h.times do |i|
          setpos(pos_y + i, pos_x)
          attron(color_pair(2)) { addstr(' ' * box_w) }
        end

        # Draw visible tracks
        visible_tracks = @filtered_playlist[@start_index, box_h] || []
        
        visible_tracks.each_with_index do |path, idx|
          draw_single_track_line(pos_y + idx, pos_x, box_w, path, idx)
        end
        
        # If no tracks, show a message
        if visible_tracks.empty? && !@search_mode
          setpos(pos_y, pos_x)
          attron(color_pair(2)) { addstr("No songs found".ljust(box_w)) }
        end
      end

      private

      def draw_single_track_line(row, col, width, path, idx)
        offset_x   = col + 1
        workable_w = width - 2
        track_str  = truncated_track_str(path, workable_w)

        abs_idx = @start_index + idx
        draw_playlist_line(row, offset_x, workable_w, track_str, abs_idx)
      end

      def truncated_track_str(path, workable_w)
        track_name = File.basename(path, File.extname(path))
        str = safe_utf8_copy(track_name)
        str.size > workable_w ? "#{str[0...(workable_w - 3)]}..." : str
      end

      def draw_playlist_line(row, offset_x, workable_w, track_str)
        if abs_idx == @current_selection
          draw_highlighted_line(row, offset_x, workable_w, track_str)
        else
          setpos(row, offset_x)
          attron(color_pair(2)) { addstr(track_str.ljust(workable_w)) }
        end
      end

      def draw_highlighted_line(row, offset_x, workable_w, track_str)
        attron(color_pair(3)) do
          setpos(row, offset_x)
          addstr(track_str.ljust(workable_w))
        end
      end
    end
  end
end
