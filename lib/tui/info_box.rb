# frozen_string_literal: true

require_relative 'box_drawer'
require_relative 'progress_bar'

module Nylera
  module TUI
    # Draws the "info" region at the bottom/right that shows song, artist, etc.
    module InfoBox
      def draw_info_box(pos_y, pos_x, box_w, box_h)
        return if box_h < 2

        draw_box_frame(pos_y, pos_x, box_w, box_h, 4)
        draw_info_contents(pos_y + 1, pos_x + 1, box_w - 2, box_h - 2)
      end

      def draw_info_contents(top_row, left_col, width_avail, height_avail)
        return if height_avail < 1

        safe_song   = safe_utf8_copy(@song_name_str)
        safe_artist = safe_utf8_copy(@artist_str)
        safe_album  = safe_utf8_copy(@album_str)
        safe_genre  = safe_utf8_copy(@genre_str)

        meta_text = "#{safe_song} | #{safe_artist} | #{safe_album} | #{safe_genre}"

        draw_info_background(top_row, left_col, width_avail)
        draw_info_data(top_row, left_col, width_avail, meta_text)

        # Progress bar draws 2 lines below
        draw_progress_bar(top_row + 2, left_col, width_avail, height_avail - 2)
      end

      private

      def draw_info_background(top_row, left_col, width_avail)
        attron(color_pair(2)) do
          setpos(top_row, left_col)
          addstr(' ' * width_avail)
        end
      end

      def draw_info_data(top_row, left_col, width_avail, meta_text)
        workable_w = width_avail - 2
        fill_info_box_line(top_row, left_col, workable_w)

        setpos(top_row, left_col + 1)
        display_str = truncated_meta_text(meta_text, workable_w)
        attron(color_pair(3)) { addstr(display_str.ljust(workable_w)) }
      end

      def fill_info_box_line(top_row, left_col, workable_w)
        attron(color_pair(3)) do
          setpos(top_row, left_col + 1)
          addstr(' ' * workable_w)
        end
      end

      def truncated_meta_text(meta_text, workable_w)
        return meta_text if meta_text.size <= workable_w

        "#{meta_text[0...(workable_w - 3)]}..."
      end
    end
  end
end
