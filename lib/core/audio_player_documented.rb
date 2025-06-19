# frozen_string_literal: true

require 'ffi'
require_relative 'audio_player_helpers'
require_relative 'mp3_decoder'
require_relative '../bindings/alsa'
require_relative '../constants'

module Nylera
  # Manages audio playback through ALSA (Advanced Linux Sound Architecture).
  #
  # This class handles the low-level audio output, including:
  # - Opening and configuring ALSA PCM devices
  # - Writing decoded audio frames to the sound card
  # - Managing playback state (play/pause/stop)
  # - Handling skip/seek requests
  # - Tracking elapsed time
  #
  # @example Basic usage
  #   decoder = MP3Decoder.new("song.mp3")
  #   elapsed = { seconds: 0.0 }
  #   mutex = Mutex.new
  #   status_cb = ->(status) { puts "Status: #{status}" }
  #   
  #   player = AudioPlayer.new(decoder, elapsed, mutex, status_cb)
  #   player.play(pause_flag, stop_flag)
  #
  # @note This class is not thread-safe. Use the provided mutex for synchronization.
  class AudioPlayer
    include AudioPlayerHelpers

    # Initialize the audio player with decoder and callbacks
    #
    # @param decoder [MP3Decoder] The decoder providing audio frames
    # @param elapsed_time [Hash] Shared hash with :seconds key for elapsed time
    # @param elapsed_mutex [Mutex] Mutex protecting elapsed_time access
    # @param status_cb [Proc] Callback for status updates (receives String)
    #
    # @raise [String] If audio device cannot be opened or configured
    def initialize(decoder, elapsed_time, elapsed_mutex, status_cb)
      @decoder      = decoder
      @elapsed_time = elapsed_time
      @elapsed_mtx  = elapsed_mutex
      @status_cb    = status_cb
      @skip_req     = { value: 0 }

      open_pcm_device
      set_hw_params
    end

    # Request a skip forward or backward
    #
    # @param seconds [Integer] Number of seconds to skip (negative for rewind)
    # @note The skip is performed asynchronously during the next audio loop iteration
    def request_skip(seconds)
      @skip_req[:value] = seconds
    end

    # Start playback loop
    #
    # This method blocks until playback is stopped. It continuously:
    # 1. Checks for pause/stop flags
    # 2. Applies any pending skip requests
    # 3. Decodes and writes audio frames
    # 4. Updates elapsed time
    #
    # @param pause_flag [Hash] Hash with :value key, true to pause
    # @param stop_flag [Hash] Hash with :value key, true to stop
    #
    # @return [void]
    def play(pause_flag, stop_flag)
      begin_play
      run_loop(pause_flag, stop_flag)
    ensure
      teardown_playback
    end

    private

    # Open the ALSA PCM device for playback
    #
    # Tries multiple device names in order of preference:
    # - pulse (for PulseAudio systems)
    # - default (ALSA default)
    # - plughw:0,0 (first hardware device with format conversion)
    # - hw:0,0 (first hardware device, direct)
    #
    # @raise [String] Descriptive error if no device can be opened
    def open_pcm_device
      @handle_ptr = FFI::MemoryPointer.new(:pointer)
      
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
          puts "Audio device opened: #{device}" if ENV['NYLERA_DEBUG']
          device_opened = true
          successful_device = device
          break
        else
          last_error = result
          puts "Failed to open #{device}: error #{result}" if ENV['NYLERA_DEBUG']
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

    # Configure ALSA hardware parameters
    #
    # Sets up the audio format, channels, sample rate, and latency.
    # Uses higher latency for PulseAudio to prevent underruns.
    #
    # @raise [String] If parameters cannot be set
    def set_hw_params
      format = ALSA::SND_PCM_FORMAT_S16_LE
      access = ALSA::SND_PCM_ACCESS_RW_INTERLEAVED

      # PulseAudio needs higher latency to prevent crackling
      latency = @device_name == 'pulse' ? 1_000_000 : 500_000
      
      result = ALSA.snd_pcm_set_params(
        @pcm_handle, format, access, @decoder.channels, @decoder.rate, 1, latency
      )
      
      if result.negative?
        raise "snd_pcm_set_params failed: #{result}"
      end
    end

    # Signal start of playback
    def begin_play
      @status_cb.call('Playing')
    end

    # Main playback loop
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

    # Process a single audio frame
    def process_frames
      data = @decoder.decode
      return false if data.empty?

      write_frames(data)
      update_elapsed(data)
      true
    end

    # Write PCM frames to ALSA
    def write_frames(pcm_data)
      buffer  = FFI::MemoryPointer.from_string(pcm_data)
      frames  = pcm_data.size / (@decoder.channels * 2)
      written = ALSA.snd_pcm_writei(@pcm_handle, buffer, frames)
      
      if written == -32 # EPIPE (underrun)
        ALSA.snd_pcm_prepare(@pcm_handle)
      elsif written < 0
        puts "Write error: #{written}" if ENV['NYLERA_DEBUG']
        ALSA.snd_pcm_prepare(@pcm_handle)
      end
    end

    # Update elapsed time based on frames written
    def update_elapsed(pcm_data)
      frames = pcm_data.size / (@decoder.channels * 2)
      @elapsed_mtx.synchronize do
        @elapsed_time[:seconds] += frames.to_f / @decoder.rate
        clamp_elapsed_time
      end
    end

    # Ensure elapsed time stays within bounds
    def clamp_elapsed_time
      dur = @decoder.duration_seconds
      @elapsed_time[:seconds] = dur if @elapsed_time[:seconds] > dur
      @elapsed_time[:seconds] = 0.0 if @elapsed_time[:seconds].negative?
    end
  end
end
