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

    def get_audio_devices
      # Start with basic devices that should work
      devices = ['default', 'plughw:0,0', 'hw:0,0']
      
      # Try to get actual device list
      if system('which aplay > /dev/null 2>&1')
        # Get first available card
        card_info = `aplay -l 2>/dev/null | grep "^card" | head -1`
        if card_info =~ /card (\d+):/
          card_num = $1
          devices.unshift("plughw:#{card_num},0")
          devices.unshift("hw:#{card_num},0")
        end
        
        # Get specific device names
        pcm_devices = `aplay -L 2>/dev/null | grep -v "^[[:space:]]" | grep -E "^(default|hw:|plughw:)" | head -5`.split("\n")
        devices = pcm_devices + devices unless pcm_devices.empty?
      end
      
      devices.uniq
    end

    def open_pcm_device
      @handle_ptr = FFI::MemoryPointer.new(:pointer)
      
      devices = get_audio_devices
      device_opened = false
      last_error = nil
      last_device = nil
      
      puts "Trying audio devices: #{devices.join(', ')}" if ENV['DEBUG']
      
      devices.each do |device|
        result = ALSA.snd_pcm_open(@handle_ptr, device, ALSA::SND_PCM_STREAM_PLAYBACK, 0)
        if result == 0
          puts "Successfully opened audio device: #{device}"
          device_opened = true
          break
        else
          last_error = result
          last_device = device
          puts "Failed to open #{device}: error #{result}" if ENV['DEBUG']
        end
      end
      
      unless device_opened
        # Provide specific error help
        error_msg = case last_error
                    when -2
                      "No audio device found. Install alsa-utils and check 'aplay -l'"
                    when -16
                      "Audio device is busy. Close other audio applications."
                    when -13
                      "Permission denied. Run: sudo usermod -a -G audio $USER"
                    when -22
                      "Invalid device '#{last_device}'. Check available devices with 'aplay -L'"
                    else
                      "Unable to open audio device. Error: #{last_error}"
                    end
        raise error_msg
      end

      @pcm_handle = @handle_ptr.read_pointer
    end

    def set_hw_params
      format = ALSA::SND_PCM_FORMAT_S16_LE
      access = ALSA::SND_PCM_ACCESS_RW_INTERLEAVED

      # Try standard parameters first
      result = ALSA.snd_pcm_set_params(
        @pcm_handle, format, access, @decoder.channels, @decoder.rate, 1, 500_000
      )
      
      if result.negative?
        # Try with different sample rate if needed
        if @decoder.rate != 44100
          result = ALSA.snd_pcm_set_params(
            @pcm_handle, format, access, @decoder.channels, 44100, 1, 500_000
          )
        end
        
        # If still failing, try mono
        if result.negative? && @decoder.channels == 2
          result = ALSA.snd_pcm_set_params(
            @pcm_handle, format, access, 1, 44100, 1, 500_000
          )
        end
        
        raise "snd_pcm_set_params failed: #{result}" if result.negative?
      end
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
    rescue => e
      puts "Playback error: #{e.message}" if ENV['DEBUG']
      false
    end

    def write_frames(pcm_data)
      buffer  = FFI::MemoryPointer.from_string(pcm_data)
      frames  = pcm_data.size / (@decoder.channels * 2)
      written = ALSA.snd_pcm_writei(@pcm_handle, buffer, frames)
      if written.negative?
        # Handle underrun
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
