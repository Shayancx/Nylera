# frozen_string_literal: true

require_relative '../constants'

module Nylera
  module TUI
    # Provides a method to draw a box (using Unicode box characters).
    module BoxDrawer
      def draw_box_frame(pos_y, pos_x, box_w, box_h, color_id)
        attron(color_pair(color_id))
        draw_box_top(pos_y, pos_x, box_w)
        draw_box_sides(pos_y, pos_x, box_w, box_h)
        draw_box_bottom(pos_y, pos_x, box_w, box_h)
        attroff(color_pair(color_id))
      end

      private

      def draw_box_top(pos_y, pos_x, box_w)
        setpos(pos_y, pos_x)
        addstr(
          Nylera::Constants::BOX_CORNER_TOP_LEFT +
          (Nylera::Constants::BOX_HORIZONTAL * (box_w - 2)) +
          Nylera::Constants::BOX_CORNER_TOP_RIGHT
        )
      end

      def draw_box_sides(pos_y, pos_x, box_w, box_h)
        (pos_y + 1).upto(pos_y + box_h - 2) do |row|
          setpos(row, pos_x)
          addstr(Nylera::Constants::BOX_VERTICAL)
          setpos(row, pos_x + box_w - 1)
          addstr(Nylera::Constants::BOX_VERTICAL)
        end
      end

      def draw_box_bottom(pos_y, pos_x, box_w, box_h)
        bottom_y = pos_y + box_h - 1
        setpos(bottom_y, pos_x)
        addstr(
          Nylera::Constants::BOX_CORNER_BOTTOM_LEFT +
          (Nylera::Constants::BOX_HORIZONTAL * (box_w - 2)) +
          Nylera::Constants::BOX_CORNER_BOTTOM_RIGHT
        )
      end
    end
  end
end
