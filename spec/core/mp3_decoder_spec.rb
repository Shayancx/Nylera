require 'spec_helper'

RSpec.describe Nylera::MP3Decoder do
  # Skip all tests if MPG123 module not loaded
  before(:all) do
    skip "MPG123 library not available" unless defined?(Nylera::MPG123)
  end
  
  let(:test_file) { 'spec/fixtures/test.mp3' }
  let(:decoder) { described_class.new(test_file) }

  before do
    # Mock MPG123 functions
    allow(Nylera::MPG123).to receive(:mpg123_new).and_return(double('handle'))
    allow(Nylera::MPG123).to receive(:mpg123_open).and_return(Nylera::MPG123::MPG123_OK)
    allow(Nylera::MPG123).to receive(:mpg123_getformat).and_return(Nylera::MPG123::MPG123_OK)
    allow(Nylera::MPG123).to receive(:mpg123_format_none)
    allow(Nylera::MPG123).to receive(:mpg123_format)
    allow(Nylera::MPG123).to receive(:mpg123_length).and_return(44100)
    allow(Nylera::MPG123).to receive(:mpg123_strerror).and_return("OK")
    
    # Mock format data
    allow_any_instance_of(FFI::MemoryPointer).to receive(:read_long).and_return(44100)
    allow_any_instance_of(FFI::MemoryPointer).to receive(:read_int).and_return(2)
    
    # Mock metadata extraction
    allow_any_instance_of(Nylera::MetadataExtractor).to receive(:extract).and_return({
      song: 'Test Song',
      artist: 'Test Artist',
      album: 'Test Album',
      genre: 'Test Genre'
    })
  end

  describe '#initialize' do
    it 'initializes decoder with file path' do
      expect { decoder }.not_to raise_error
    end

    it 'sets audio format properties' do
      expect(decoder.rate).to eq(44100)
      expect(decoder.channels).to eq(2)
    end
  end

  describe '#decode' do
    before do
      allow(Nylera::MPG123).to receive(:mpg123_read).and_return(Nylera::MPG123::MPG123_OK)
      allow_any_instance_of(FFI::MemoryPointer).to receive(:read_string).and_return('audio_data')
    end

    it 'returns decoded audio data' do
      expect(decoder.decode).to eq('audio_data')
    end
  end

  describe '#seek_relative' do
    before do
      allow(Nylera::MPG123).to receive(:mpg123_tell).and_return(1000)
      allow(Nylera::MPG123).to receive(:mpg123_seek).and_return(0)
    end

    it 'seeks forward in the stream' do
      # Fix: Calculate correct frame position (1 second at 44100Hz = 44100 frames)
      expect(Nylera::MPG123).to receive(:mpg123_seek).with(anything, 1000 + 44100, Nylera::MPG123::SEEK_SET)
      decoder.seek_relative(1)
    end

    it 'seeks backward in the stream' do
      expect(Nylera::MPG123).to receive(:mpg123_seek).with(anything, 0, Nylera::MPG123::SEEK_SET)
      decoder.seek_relative(-10)
    end
  end

  describe '#close' do
    it 'closes and deletes the mpg123 handle' do
      expect(Nylera::MPG123).to receive(:mpg123_close)
      expect(Nylera::MPG123).to receive(:mpg123_delete)
      decoder.close
    end
  end
end
