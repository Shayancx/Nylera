# frozen_string_literal: true

require_relative '../constants'
require_relative '../bindings/mpg123'
require_relative '../bindings/alsa'
require_relative '../metadata/metadata_extractor'
require_relative 'mp3_player_app_helpers'
require_relative 'audio_player'
require_relative 'mp3_decoder'
require_relative '../tui/tui_optimized'

module Nylera
  # Main application controller for the MP3 player.
  # 
  # This class coordinates all major components:
  # - Audio playback (via AudioPlayer)
  # - User interface (via TUI::MainTui)
  # - Playlist management
  # - Thread synchronization
  #
  # @example Basic usage
  #   app = Nylera::MP3PlayerApp.new("~/Music")
  #   app.run  # Blocks until user quits
  #
  # @note This class manages its own threads for audio playback
  class MP3PlayerApp
    include Mp3PlayerAppHelpers

    # Initialize the MP3 player application
    #
    # @param music_dir [String] Path to directory containing MP3 files
    # @raise [SystemExit] If no MP3 files found or initialization fails
    def initialize(music_dir = Nylera::Constants::DEFAULT_MUSIC_DIR)
      setup_flags_and_mutexes
      @music_dir = music_dir

      # Initialize the mpg123 library globally
      MPG123.mpg123_init

      @playlist      = load_playlist
      @current_track = nil
      @player_thread = nil
    rescue StandardError => e
      warn "Initialization Error: #{e.message}"
      exit 1
    end

    # Start the application main loop
    #
    # This method blocks until the user exits the application.
    # It initializes the TUI and processes user actions.
    #
    # @yield [Symbol, Integer] User actions to handle
    def run
      @tui = Nylera::TUI::MainTui.new(@playlist, @elapsed_time, @elapsed_mtx, method(:current_status))
      @tui.start do |action|
        handle_action(action)
      end
    ensure
      cleanup
    end

    private

    # Initialize synchronization primitives and shared state
    def setup_flags_and_mutexes
      @pause_flag    = { value: false }  # Shared pause state
      @stop_flag     = { value: false }   # Shared stop signal
      @mutex         = Mutex.new          # Protects player thread
      @status_mtx    = Mutex.new          # Protects status string
      @elapsed_time  = { seconds: 0.0 }   # Shared elapsed time
      @elapsed_mtx   = Mutex.new          # Protects elapsed time
      @status        = 'Stopped'          # Current playback status
    end

    # Load MP3 files from the music directory
    #
    # @return [Array<String>] Sorted list of MP3 file paths
    # @raise [SystemExit] If no MP3 files found
    def load_playlist
      files = Dir.glob(File.join(@music_dir, '**', '*.mp3')).sort
      if files.empty?
        warn "No MP3 files found in directory: #{@music_dir}"
        exit 1
      end
      files
    end

    # Route user actions to appropriate handlers
    #
    # @param action [Symbol, Integer] The action to perform
    def handle_action(action)
      case action
      when :pause_resume then toggle_pause
      when :ff_10sec     then skip(10)
      when :rw_10sec     then skip(-10)
      when Integer       then play_track(action)
      end
    end

    # Start playback of a specific track
    #
    # @param index [Integer] Index in the filtered playlist
    def play_track(index)
      perform_play_track(index)
    end

    # Toggle pause/resume state
    #
    # Thread-safe method to pause or resume playback
    def toggle_pause
      @mutex.synchronize do
        return unless @player_thread&.alive?

        @pause_flag[:value] = !@pause_flag[:value]
        update_status(@pause_flag[:value] ? 'Paused' : 'Playing')
      end
    end

    # Skip forward or backward in the current track
    #
    # @param seconds [Integer] Number of seconds to skip (negative for rewind)
    def skip(seconds)
      @mutex.synchronize do
        return unless @player_thread&.alive? && @audio_player

        @audio_player.request_skip(seconds)
      end
    end

    # Stop current playback
    def stop_playback
      perform_stop_playback
    end

    # Update the playback status string
    #
    # @param new_status [String] New status to set
    def update_status(new_status)
      @status_mtx.synchronize { @status = new_status }
    end

    # Get the current playback status
    #
    # @return [String] Current status
    def current_status
      @status_mtx.synchronize { @status }
    end

    # Clean up resources on exit
    def cleanup
      stop_playback
      MPG123.mpg123_exit
    end
  end
end
