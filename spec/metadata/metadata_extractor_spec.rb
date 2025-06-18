require 'spec_helper'
require 'tempfile'

RSpec.describe Nylera::MetadataExtractor do
  let(:test_file) { Tempfile.new(['test', '.mp3']) }
  let(:extractor) { described_class.new(test_file.path) }

  after { test_file.unlink }

  describe '#extract' do
    context 'with no metadata' do
      it 'returns default values' do
        result = extractor.extract
        expect(result).to eq({
          song: 'Unknown',
          artist: 'Unknown',
          album: 'Unknown',
          genre: 'Unknown'
        })
      end
    end

    context 'with ID3v1 tag' do
      before do
        # Write a minimal ID3v1 tag
        test_file.write("\x00" * 128) # Pad file
        test_file.seek(-128, IO::SEEK_END)
        test_file.write("TAG")
        test_file.write("Test Song".ljust(30, "\x00"))
        test_file.write("Test Artist".ljust(30, "\x00"))
        test_file.write("Test Album".ljust(30, "\x00"))
        test_file.write("2023".ljust(4, "\x00"))
        test_file.write("Comment".ljust(30, "\x00"))
        test_file.write("\x00") # Genre
        test_file.rewind
      end

      it 'extracts ID3v1 metadata' do
        result = extractor.extract
        expect(result[:song]).to eq('Test Song')
        expect(result[:artist]).to eq('Test Artist')
        expect(result[:album]).to eq('Test Album')
      end
    end
  end

  describe '#clean_string' do
    it 'removes null bytes and strips whitespace' do
      dirty_string = "Test\x00String  "
      expect(extractor.send(:clean_string, dirty_string)).to eq('TestString')
    end

    it 'returns Unknown for nil input' do
      expect(extractor.send(:clean_string, nil)).to eq('Unknown')
    end
  end

  describe '#genre_name' do
    it 'returns genre name for valid ID' do
      expect(extractor.send(:genre_name, 0)).to eq('Blues')
      expect(extractor.send(:genre_name, 1)).to eq('Classic Rock')
    end

    it 'returns Unknown for invalid ID' do
      expect(extractor.send(:genre_name, nil)).to eq('Unknown')
      expect(extractor.send(:genre_name, -1)).to eq('Unknown')
      expect(extractor.send(:genre_name, 999)).to eq('Unknown')
    end
  end
end
