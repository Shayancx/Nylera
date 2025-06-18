# frozen_string_literal: true

module Nylera
  module TUI
    # Shared utility methods
    module Utils
      def current_elapsed
        @elapsed_mutex.synchronize { @elapsed_time[:seconds] }
      end

      def format_time(seconds)
        total_secs = seconds.to_i
        format('%<min>02d:%<sec>02d',
               min: total_secs / 60,
               sec: total_secs % 60)
      end

      def safe_utf8_copy(str)
        return '' if str.nil?

        duped_str = str.dup
        duped_str.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip
      rescue StandardError
        ''
      end
    end
  end
end
