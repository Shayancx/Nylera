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
      
      # For PulseAudio systems, try pulse first
      devices_to_try = if system('pactl info > /dev/null 2>&1')
                         ['pulse', 'default', 'plughw:0,0', 'hw:0,0']
                       else
                         ['default', 'plughw:0,0', 'hw:0,0']
                       end
      
      device_opened = false
      last_error = nil
      successful_device = nil
      
      devices_to_try.each do |device|
        result = ALSA.snd_pcm_open(@handle_ptr, device, ALSA::SND_PCM_STREAM_PLAYBACK, 0)
        if result == 0
          puts "Audio device opened: #{device}"
          device_opened = true
          successful_device = device
          break
        else
          last_error = result
          puts "Failed to open #{device}: error #{result}" if ENV['DEBUG']
        end
      end
      
      unless device_opened
        error_msg = case last_error
                    when -2
                      "No audio device found. Install alsa-plugins-pulseaudio for PulseAudio support."
                    when -16
                      "Audio device is busy. Close other audio applications."
                    when -13
                      "Permission denied. Run: sudo usermod -a -G audio $USER"
                    else
                      "Unable to open audio device. Error: #{last_error}"
                    end
        raise error_msg
      end

      @pcm_handle = @handle_ptr.read_pointer
      @device_name = successful_device
    end

    def set_hw_params
      format = ALSA::SND_PCM_FORMAT_S16_LE
      access = ALSA::SND_PCM_ACCESS_RW_INTERLEAVED

      # More lenient parameters for PulseAudio
      latency = @device_name == 'pulse' ? 1_000_000 : 500_000
      
      result = ALSA.snd_pcm_set_params(
        @pcm_handle, format, access, @decoder.channels, @decoder.rate, 1, latency
      )
      
      if result.negative?
        raise "snd_pcm_set_params failed: #{result}"
      end
    end

    def begin_play
      @status_cb.call('Playing')
    end

    def run_loop(pause_flag, stop_flag)
      loop do
        break if stop_flag[:value]

        apply_skip
        
        if pause_flag[:value]
          @status_cb.call('Paused')
          sleep(0.1)
          Thread.pass
          next
        end

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
      
      if written == -32 # EPIPE (underrun)
        ALSA.snd_pcm_prepare(@pcm_handle)
      elsif written < 0
        puts "Write error: #{written}" if ENV['DEBUG']
        ALSA.snd_pcm_prepare(@pcm_handle)
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
