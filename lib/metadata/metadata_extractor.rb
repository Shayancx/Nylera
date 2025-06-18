# frozen_string_literal: true

module Nylera
  ##
  # Extracts ID3v1 and ID3v2 metadata from an MP3 file.
  # Splits out logic into ID3v1Reader & ID3v2Reader modules for clarity.
  #
  class MetadataExtractor
    ID3V1_TAG_SIZE = 128

    ##
    # Provides methods to read ID3v1 tags
    #
    module ID3v1Reader
      def extract_id3v1(file_path, metadata)
        return unless can_read_id3v1?(file_path)

        File.open(file_path, 'rb') do |f|
          f.seek(-ID3V1_TAG_SIZE, IO::SEEK_END)
          tag = f.read(ID3V1_TAG_SIZE)
          next unless tag && tag[0..2] == 'TAG'

          apply_id3v1_tag_to_metadata(tag, metadata)
        end
      rescue StandardError
        # ignore any read errors
      end

      private

      def can_read_id3v1?(path)
        File.size(path) >= ID3V1_TAG_SIZE
      end

      def apply_id3v1_tag_to_metadata(tag, metadata)
        metadata[:song]   = clean_string(tag[3..32])
        metadata[:artist] = clean_string(tag[33..62])
        metadata[:album]  = clean_string(tag[63..92])
        genre_id          = tag[127].ord
        metadata[:genre]  = genre_name(genre_id)
      end
    end

    ##
    # Provides methods to read ID3v2 tags
    #
    module ID3v2Reader
      ##
      # Extract ID3v2 from a given file
      #
      def extract_id3v2(file_path, metadata)
        File.open(file_path, 'rb') do |f|
          header = f.read(10)
          next unless header && header[0..2] == 'ID3'

          size     = syncsafe_to_size(header[6..9])
          tag_data = f.read(size)
          parse_id3v2(tag_data, metadata) if tag_data
        end
      rescue StandardError
        # ignore
      end

      def parse_id3v2(data, metadata)
        pos = 0
        while pos < data.bytesize - 10
          frame_header = data[pos, 10]
          break if invalid_frame_header?(frame_header)

          frame_id    = frame_header[0..3]
          frame_size  = frame_header[4..7].unpack1('N')
          frame_content = data[pos + 10, frame_size]

          update_metadata_from_frame(frame_id, frame_content, metadata)
          pos += 10 + frame_size
        end
      end

      private

      def invalid_frame_header?(frame_header)
        frame_header.nil? || frame_header.bytesize < 10 || frame_header[0..3].strip.empty?
      end

      def update_metadata_from_frame(frame_id, frame_content, metadata)
        case frame_id
        when 'TIT2'
          metadata[:song]   = clean_text(frame_content)
        when 'TPE1'
          metadata[:artist] = clean_text(frame_content)
        when 'TALB'
          metadata[:album]  = clean_text(frame_content)
        when 'TCON'
          metadata[:genre]  = clean_text(frame_content)
        end
      end
    end

    include ID3v1Reader
    include ID3v2Reader

    def initialize(file_path)
      @file_path = file_path
      @metadata = {
        song: 'Unknown',
        artist: 'Unknown',
        album: 'Unknown',
        genre: 'Unknown'
      }
    end

    def extract
      extract_id3v1(@file_path, @metadata)
      extract_id3v2(@file_path, @metadata)
      @metadata
    end

    private

    def clean_string(str)
      return 'Unknown' unless str

      str.force_encoding('ISO-8859-1').strip.gsub(/\0/, '')
    rescue StandardError
      'Unknown'
    end

    def clean_text(text)
      return 'Unknown' unless text && !text.empty?

      encoding_byte = text.getbyte(0)
      raw = text.byteslice(1..-1)
      decode_text_by_encoding(encoding_byte, raw)
    rescue StandardError
      'Unknown'
    end

    def decode_text_by_encoding(encoding_byte, raw)
      case encoding_byte
      when 0 then decode_iso_text(raw)
      when 1 then decode_utf16_bom(raw)
      when 2 then decode_utf16_be(raw)
      when 3 then decode_utf8_text(raw)
      else decode_fallback(raw)
      end
    end

    def decode_iso_text(raw)
      raw.force_encoding('ISO-8859-1').strip.gsub(/\0/, '')
    end

    def decode_utf16_bom(raw)
      raw.encode('UTF-8', 'UTF-16').strip.gsub(/\0/, '')
    end

    def decode_utf16_be(raw)
      raw.encode('UTF-8', 'UTF-16BE').strip.gsub(/\0/, '')
    end

    def decode_utf8_text(raw)
      raw.force_encoding('UTF-8').strip.gsub(/\0/, '')
    end

    def decode_fallback(raw)
      raw.force_encoding('ISO-8859-1').strip.gsub(/\0/, '')
    end

    GENRES = [
      'Blues', 'Classic Rock', 'Country', 'Dance', 'Disco', 'Funk',
      'Grunge', 'Hip-Hop', 'Jazz', 'Metal', 'New Age', 'Oldies',
      'Hard Rock'
      # ... Add more if needed ...
    ].freeze

    def genre_name(genre_id)
      return 'Unknown' unless genre_id && genre_id >= 0

      GENRES[genre_id] || 'Unknown'
    end

    def syncsafe_to_size(syncsafe_bytes)
      bytes = syncsafe_bytes.bytes
      (bytes[0] << 21) | (bytes[1] << 14) | (bytes[2] << 7) | bytes[3]
    end
  end
end
