#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

puts "Testing Nylera components..."

# Test 1: Check if constants load
begin
  require 'constants'
  puts "✓ Constants loaded successfully"
rescue => e
  puts "✗ Constants failed: #{e.message}"
end

# Test 2: Check if FFI bindings load
begin
  require 'bindings/mpg123'
  require 'bindings/alsa'
  puts "✓ FFI bindings loaded"
rescue => e
  puts "✗ FFI bindings failed: #{e.message}"
  puts "  Make sure libasound2-dev and libmpg123-dev are installed"
end

# Test 3: Check metadata extractor
begin
  require 'metadata/metadata_extractor'
  puts "✓ Metadata extractor loaded"
rescue => e
  puts "✗ Metadata extractor failed: #{e.message}"
end

# Test 4: Check if music directory exists
music_dir = ENV.fetch('MUSIC_DIR', File.expand_path('~/Musik'))
if Dir.exist?(music_dir)
  mp3_count = Dir.glob(File.join(music_dir, '**', '*.mp3')).count
  puts "✓ Music directory found: #{music_dir} (#{mp3_count} MP3 files)"
else
  puts "✗ Music directory not found: #{music_dir}"
  puts "  Set MUSIC_DIR environment variable or create ~/Musik"
end

puts "\nIf all checks pass, run: ruby bin/nylera.rb"
