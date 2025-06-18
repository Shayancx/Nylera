# frozen_string_literal: true

require_relative '../bindings/mpg123'
require_relative '../metadata/metadata_extractor'
require_relative '../constants'

module Nylera
  # Decodes MP3 frames via mpg123
  class MP3Decoder
    attr_reader :duration_seconds, :rate, :channels, :encoding, :title, :artist, :album, :genre

    def initialize(file_path)
      @file   = file_path
      @handle = MPG123.mpg123_new(nil, nil)
      check_handle

      result = MPG123.mpg123_open(@handle, @file)
      raise "Failed to open file: #{mpg123_err}" unless result == MPG123::MPG123_OK

      acquire_format
      calc_duration
      load_metadata
    end

    def decode
      ptr, bytes = read_mpg123_data
      return '' if ptr.nil? || bytes.zero?

      ptr.read_string(bytes)
    end

    def seek_relative(sec)
      current_frame = MPG123.mpg123_tell(@handle)
      return if current_frame.negative?

      jump_frames = (sec * @rate).to_i
      new_frame   = [0, current_frame + jump_frames].max
      last_frame  = (@duration_seconds * @rate).to_i
      new_frame   = last_frame if new_frame > last_frame

      MPG123.mpg123_seek(@handle, new_frame, MPG123::SEEK_SET)
    end

    def close
      MPG123.mpg123_close(@handle)
      MPG123.mpg123_delete(@handle)
    end

    private

    def check_handle
      raise "Failed to create mpg123 handle: #{mpg123_err}" unless @handle
    end

    def mpg123_err
      MPG123.mpg123_strerror(@handle)
    end

    def acquire_format
      decoder_format_data
      enforce_16bit
    end

    def decoder_format_data
      rate_ptr     = FFI::MemoryPointer.new(:long)
      channels_ptr = FFI::MemoryPointer.new(:int)
      encoding_ptr = FFI::MemoryPointer.new(:int)

      result = MPG123.mpg123_getformat(@handle, rate_ptr, channels_ptr, encoding_ptr)
      raise "Failed to get format: #{mpg123_err}" unless result == MPG123::MPG123_OK

      @rate     = rate_ptr.read_long
      @channels = channels_ptr.read_int
      @encoding = encoding_ptr.read_int
    end

    def enforce_16bit
      MPG123.mpg123_format_none(@handle)
      MPG123.mpg123_format(@handle, @rate, @channels, MPG123::MPG123_ENC_SIGNED_16)
    end

    def calc_duration
      total_frames = MPG123.mpg123_length(@handle)
      @duration_seconds = if total_frames.positive?
                            total_frames.to_f / @rate
                          else
                            0.0
                          end
    end

    def load_metadata
      meta = Nylera::MetadataExtractor.new(@file).extract
      @title  = meta[:song]   || File.basename(@file, File.extname(@file))
      @artist = meta[:artist] || 'Unknown'
      @album  = meta[:album]  || 'Unknown'
      @genre  = meta[:genre]  || 'Unknown'
    end

    def read_mpg123_data
      buf_ptr   = FFI::MemoryPointer.new(:char, Constants::BUFFER_SIZE)
      bytes_ptr = FFI::MemoryPointer.new(:int)

      result = MPG123.mpg123_read(@handle, buf_ptr, Constants::BUFFER_SIZE, bytes_ptr)
      bytes  = bytes_ptr.read_int

      valid_result = [MPG123::MPG123_OK, MPG123::MPG123_DONE, MPG123::MPG123_NEW_FORMAT]
      return [nil, 0] unless valid_result.include?(result)

      [buf_ptr, bytes]
    end
  end
end
