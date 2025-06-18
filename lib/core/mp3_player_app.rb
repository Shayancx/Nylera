# frozen_string_literal: true

require_relative '../constants'
require_relative '../bindings/mpg123'
require_relative '../bindings/alsa'
require_relative '../metadata/metadata_extractor'
require_relative 'mp3_player_app_helpers'
require_relative 'audio_player'
require_relative 'mp3_decoder'
require_relative '../tui/tui'

module Nylera
  # Main application that wires everything together
  class MP3PlayerApp
    include Mp3PlayerAppHelpers

    def initialize(music_dir = Nylera::Constants::DEFAULT_MUSIC_DIR)
      setup_flags_and_mutexes
      @music_dir = music_dir

      MPG123.mpg123_init

      @playlist      = load_playlist
      @current_track = nil
      @player_thread = nil
    rescue StandardError => e
      warn "Initialization Error: #{e.message}"
      exit 1
    end

    def run
      @tui = Nylera::TUI::MainTui.new(@playlist, @elapsed_time, @elapsed_mtx, method(:current_status))
      @tui.start do |action|
        handle_action(action)
      end
    ensure
      cleanup
    end

    private

    def setup_flags_and_mutexes
      @pause_flag    = { value: false }
      @stop_flag     = { value: false }
      @mutex         = Mutex.new
      @status_mtx    = Mutex.new
      @elapsed_time  = { seconds: 0.0 }
      @elapsed_mtx   = Mutex.new
      @status        = 'Stopped'
    end

    def load_playlist
      files = Dir.glob(File.join(@music_dir, '**', '*.mp3')).sort
      if files.empty?
        warn "No MP3 files found in directory: #{@music_dir}"
        exit 1
      end
      files
    end

    def handle_action(action)
      case action
      when :pause_resume then toggle_pause
      when :ff_10sec     then skip(10)
      when :rw_10sec     then skip(-10)
      when Integer       then play_track(action)
      end
    end

    def play_track(index)
      perform_play_track(index)
    end

    def toggle_pause
      @mutex.synchronize do
        return unless @player_thread&.alive?

        @pause_flag[:value] = !@pause_flag[:value]
        update_status(@pause_flag[:value] ? 'Paused' : 'Playing')
      end
    end

    def skip(seconds)
      @mutex.synchronize do
        return unless @player_thread&.alive? && @audio_player

        @audio_player.request_skip(seconds)
      end
    end

    def stop_playback
      perform_stop_playback
    end

    def update_status(new_status)
      @status_mtx.synchronize { @status = new_status }
    end

    def current_status
      @status_mtx.synchronize { @status }
    end

    def cleanup
      stop_playback
      MPG123.mpg123_exit
    end
  end
end
