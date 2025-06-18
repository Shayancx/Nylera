# frozen_string_literal: true

require 'ffi'
require_relative 'audio_player_helpers'
require_relative 'mp3_decoder'
require_relative '../bindings/alsa'
require_relative '../constants'

module Nylera
  # Manages audio playback (decoding + writing to ALSA).
  class AudioPlayer
    include AudioPlayerHelpers

    def initialize(decoder, elapsed_time, elapsed_mutex, status_cb)
      @decoder      = decoder
      @elapsed_time = elapsed_time
      @elapsed_mtx  = elapsed_mutex
      @status_cb    = status_cb
      @skip_req     = { value: 0 }

      open_pcm_device
      set_hw_params
    end

    def request_skip(seconds)
      @skip_req[:value] = seconds
    end

    def play(pause_flag, stop_flag)
      begin_play
      run_loop(pause_flag, stop_flag)
    ensure
      teardown_playback
    end

    private

    def open_pcm_device
      @handle_ptr = FFI::MemoryPointer.new(:pointer)
      result = ALSA.snd_pcm_open(@handle_ptr, 'default:CARD=Generic_1', ALSA::SND_PCM_STREAM_PLAYBACK, 0)
      raise "Unable to open PCM device: #{result}" if result.negative?

      @pcm_handle = @handle_ptr.read_pointer
    end

    def set_hw_params
      format = ALSA::SND_PCM_FORMAT_S16_LE
      access = ALSA::SND_PCM_ACCESS_RW_INTERLEAVED

      result = ALSA.snd_pcm_set_params(
        @pcm_handle, format, access, @decoder.channels, @decoder.rate, 1, 500_000
      )
      raise "snd_pcm_set_params failed: #{result}" if result.negative?
    end

    def begin_play
      @status_cb.call('Playing')
    end

    def run_loop(pause_flag, stop_flag)
      loop do
        break if stop_flag[:value]

        apply_skip
        handle_pause(pause_flag) && next

        @status_cb.call('Playing')
        break unless process_frames

        Thread.pass
      end
    end

    def handle_pause(pause_flag)
      return false unless pause_flag[:value]

      @status_cb.call('Paused')
      sleep(0.1)
      Thread.pass
      true
    end

    def process_frames
      data = @decoder.decode
      return false if data.empty?

      write_frames(data)
      update_elapsed(data)
      true
    end

    def write_frames(pcm_data)
      buffer  = FFI::MemoryPointer.from_string(pcm_data)
      frames  = pcm_data.size / (@decoder.channels * 2)
      written = ALSA.snd_pcm_writei(@pcm_handle, buffer, frames)
      if written.negative?
        ALSA.snd_pcm_prepare(@pcm_handle)
      else
        @status_cb.call('Playing')
      end
    end

    def update_elapsed(pcm_data)
      frames = pcm_data.size / (@decoder.channels * 2)
      @elapsed_mtx.synchronize do
        @elapsed_time[:seconds] += frames.to_f / @decoder.rate
        clamp_elapsed_time
      end
    end

    def clamp_elapsed_time
      dur = @decoder.duration_seconds
      @elapsed_time[:seconds] = dur if @elapsed_time[:seconds] > dur
      @elapsed_time[:seconds] = 0.0 if @elapsed_time[:seconds].negative?
    end
  end
end
