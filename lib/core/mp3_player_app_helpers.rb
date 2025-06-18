# frozen_string_literal: true

module Nylera
  # Mp3PlayerAppHelpers is mixed into MP3PlayerApp,
  # providing helper methods for playback & stop logic
  module Mp3PlayerAppHelpers
    private

    def perform_stop_playback
      return unless @player_thread&.alive?

      @stop_flag[:value] = true
      @player_thread.join
      @player_thread = nil
      @audio_player  = nil
      @status        = 'Stopped'

      finalize_stop
    end

    def finalize_stop
      if @current_track
        track_name = File.basename(@current_track, File.extname(@current_track))
        @tui.update(0, @status, track_name, 0.0)
        @current_track = nil
      else
        @tui.update(0, @status, 'None', 0.0)
      end
    end

    def perform_play_track(index)
      handle_existing_playback
      return unless start_new_track(index)

      @elapsed_mtx.synchronize { @elapsed_time[:seconds] = 0.0 }
      create_audio_player
    rescue StandardError => e
      @tui.update(index, 'Error', e.message)
    end

    def handle_existing_playback
      stop_playback if @player_thread&.alive?
      @pause_flag[:value] = false
      @stop_flag[:value]  = false
    end

    def start_new_track(index)
      selected_path = @tui.filtered_playlist[index]
      return false unless selected_path

      @current_track = selected_path
      build_decoder_and_metadata(index)
      true
    end

    def build_decoder_and_metadata(index)
      decoder = Nylera::MP3Decoder.new(@current_track)
      update_tui_metadata(index, decoder)
      @decoder_for_player = decoder
    end

    def update_tui_metadata(index, decoder)
      song_name = decoder.title  || File.basename(@current_track, File.extname(@current_track))
      artist    = decoder.artist || 'Unknown'
      album     = decoder.album  || 'Unknown'
      genre     = decoder.genre  || 'Unknown'

      @tui.instance_variable_set(:@song_name_str, song_name)
      @tui.instance_variable_set(:@artist_str,    artist)
      @tui.instance_variable_set(:@album_str,     album)
      @tui.instance_variable_set(:@genre_str,     genre)

      @tui.update(index, 'Playing', song_name, decoder.duration_seconds)
    end

    def create_audio_player
      @audio_player = Nylera::AudioPlayer.new(@decoder_for_player, @elapsed_time, @elapsed_mtx, method(:update_status))
      @player_thread = Thread.new do
        @audio_player.play(@pause_flag, @stop_flag)
      end
    end

    def toggle_pause
      @mutex.synchronize do
        if @pause_flag[:value]
          @pause_flag[:value] = false
          @status = 'Playing'
        else
          @pause_flag[:value] = true
          @status = 'Paused'
        end
      end
    end
  end
end
