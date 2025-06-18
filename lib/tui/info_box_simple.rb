# frozen_string_literal: true

require_relative 'box_drawer'

module Nylera
  module TUI
    # Simplified info box without complex progress bar
    module InfoBox
      def draw_info_box(pos_y, pos_x, box_w, box_h)
        return if box_h < 2

        draw_box_frame(pos_y, pos_x, box_w, box_h, 4)
        
        # Simple status display
        if box_h >= 3
          setpos(pos_y + 1, pos_x + 2)
          attron(color_pair(2)) do
            status_text = "Status: #{@status} | Track: #{@song_name_str}"
            display_text = status_text[0...(box_w - 4)] if status_text.length > box_w - 4
            addstr(display_text || status_text)
          end
        end
      end
    end
  end
end
