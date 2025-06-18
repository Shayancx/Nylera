# frozen_string_literal: true

module Nylera
  module TUI
    # Draws the time/progress bar
    module ProgressBar
      def draw_progress_bar(pos_y, pos_x, bar_w, leftover_h)
        return unless leftover_h.positive?

        setup_progress_area(pos_y, pos_x, bar_w)

        time_disp = build_time_disp
        offset_x  = pos_x + 1
        workable_w = bar_w - 2

        draw_time_disp(pos_y, offset_x, time_disp)
        fill_len, empty_len = compute_progress_bar(time_disp, workable_w)

        attron(color_pair(1)) { addstr('━' * fill_len) }
        attron(color_pair(5)) { addstr('━' * empty_len) }
      end

      private

      def setup_progress_area(pos_y, pos_x, bar_w)
        setpos(pos_y, pos_x)
        attron(color_pair(2)) { addstr(' ' * bar_w) }
      end

      def build_time_disp
        e_str = format_time(current_elapsed)
        t_str = format_time(@total_duration)
        "#{e_str} / #{t_str}"
      end

      def draw_time_disp(pos_y, offset_x, time_disp)
        setpos(pos_y, offset_x)
        attron(color_pair(2)) { addstr("#{time_disp} ") }
      end

      def compute_progress_bar(time_disp, workable_w)
        used       = time_disp.size + 1
        bar_length = workable_w - used
        bar_length = 10 if bar_length < 10

        fill_len, empty_len = calc_fill_empty(bar_length)
        [fill_len, empty_len]
      end

      def calc_fill_empty(bar_length)
        prog = progress_ratio
        fill_len  = (bar_length * prog).to_i
        empty_len = bar_length - fill_len
        [fill_len, empty_len]
      end

      def progress_ratio
        return 0.0 unless @total_duration.positive?

        ratio = current_elapsed / @total_duration
        ratio > 1.0 ? 1.0 : ratio
      end
    end
  end
end
