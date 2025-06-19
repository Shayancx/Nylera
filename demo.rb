#!/usr/bin/env ruby

# Demo script to test Nylera without audio hardware

$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))

require 'tmpdir'
require 'fileutils'

# Create a temporary music directory with fake MP3s
music_dir = Dir.mktmpdir
puts "Creating demo music directory: #{music_dir}"

# Create some fake MP3 files
songs = [
  "Artist1 - Song1.mp3",
  "Artist1 - Song2.mp3",
  "Artist2 - Amazing Track.mp3",
  "Artist3 - Best Hit.mp3",
  "Artist3 - Another Song.mp3"
]

songs.each do |song|
  File.write(File.join(music_dir, song), "\xFF\xFB\x90\x00" * 100)
end

puts "Created #{songs.length} demo MP3 files"

# Set environment to use demo directory
ENV['NYLERA_MUSIC_DIR'] = music_dir
ENV['NYLERA_DEBUG'] = 'true'

# Mock the audio libraries to avoid hardware requirements
require 'constants'
require 'bindings/mpg123'
require 'bindings/alsa'

module Nylera
  module MPG123
    class << self
      alias_method :original_mpg123_init, :mpg123_init if method_defined?(:mpg123_init)
      alias_method :original_mpg123_open, :mpg123_open if method_defined?(:mpg123_open)
      
      def mpg123_init
        puts "[DEMO] MPG123 initialized (mocked)"
        0
      end
      
      def mpg123_open(handle, file)
        puts "[DEMO] Opening file: #{file}"
        0
      end
    end
  end
  
  module ALSA
    class << self
      alias_method :original_snd_pcm_open, :snd_pcm_open if method_defined?(:snd_pcm_open)
      
      def snd_pcm_open(handle_ptr, device, stream, mode)
        puts "[DEMO] ALSA device opened: #{device} (mocked)"
        # Write a fake pointer
        handle_ptr.write_pointer(FFI::Pointer.new(0x12345678)) if handle_ptr.respond_to?(:write_pointer)
        0
      end
      
      def snd_pcm_set_params(handle, format, access, channels, rate, soft_resample, latency)
        puts "[DEMO] ALSA params set (mocked)"
        0
      end
    end
  end
end

# Now try to run the application
puts "\nStarting Nylera in demo mode..."
puts "Press 'q' to quit"
puts "Use arrow keys to navigate"
puts "Press SPACE to play/pause"
puts "Press ':S' to search"
puts "\n"

begin
  require 'core/mp3_player_app'
  app = Nylera::MP3PlayerApp.new(music_dir)
  app.run
rescue Exception => e
  puts "\nDemo ended: #{e.message}"
  puts e.backtrace.first(5)
ensure
  FileUtils.rm_rf(music_dir)
  puts "\nCleaned up demo directory"
end
