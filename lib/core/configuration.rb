# frozen_string_literal: true

module Nylera
  # Configuration management for Nylera
  class Configuration
    attr_accessor :music_dir, :buffer_size, :refresh_rate, :skip_seconds
    attr_accessor :nav_box_width, :info_box_height, :double_tap_window
    attr_accessor :colors, :debug_mode

    def initialize
      # Audio settings
      @music_dir = ENV.fetch('NYLERA_MUSIC_DIR', File.expand_path('~/Musik'))
      @buffer_size = ENV.fetch('NYLERA_BUFFER_SIZE', '1024').to_i
      
      # UI settings
      @refresh_rate = ENV.fetch('NYLERA_REFRESH_RATE', '50').to_i
      @nav_box_width = ENV.fetch('NYLERA_NAV_WIDTH', '37').to_i
      @info_box_height = ENV.fetch('NYLERA_INFO_HEIGHT', '5').to_i
      @double_tap_window = ENV.fetch('NYLERA_DOUBLE_TAP', '0.3').to_f
      
      # Playback settings
      @skip_seconds = ENV.fetch('NYLERA_SKIP_SECONDS', '10').to_i
      
      # Debug settings
      @debug_mode = ENV['NYLERA_DEBUG'] == 'true'
      
      # Color scheme - using color pair indices
      @colors = {
        progress_fill: 1,   # Color pair 1
        text: 2,            # Color pair 2
        highlight: 3,       # Color pair 3
        border: 4,          # Color pair 4
        progress_empty: 5   # Color pair 5
      }
    end

    def self.instance
      @instance ||= new
    end
  end
end
