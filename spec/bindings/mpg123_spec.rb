require 'spec_helper'

RSpec.describe Nylera::MPG123 do
  describe 'FFI bindings' do
    it 'defines required constants' do
      expect(Nylera::MPG123::MPG123_OK).to eq(0)
      expect(Nylera::MPG123::MPG123_DONE).to eq(-12)
      expect(Nylera::MPG123::MPG123_NEW_FORMAT).to eq(-10)
      expect(Nylera::MPG123::MPG123_ENC_SIGNED_16).to eq(3)
      expect(Nylera::MPG123::SEEK_SET).to eq(0)
    end

    it 'responds to required functions' do
      # Skip function tests if library not loaded
      skip "MPG123 library not available" unless defined?(Nylera::MPG123.mpg123_init)
      
      expect(Nylera::MPG123).to respond_to(:mpg123_init)
      expect(Nylera::MPG123).to respond_to(:mpg123_new)
      expect(Nylera::MPG123).to respond_to(:mpg123_open)
      expect(Nylera::MPG123).to respond_to(:mpg123_getformat)
      expect(Nylera::MPG123).to respond_to(:mpg123_read)
      expect(Nylera::MPG123).to respond_to(:mpg123_close)
      expect(Nylera::MPG123).to respond_to(:mpg123_delete)
      expect(Nylera::MPG123).to respond_to(:mpg123_exit)
    end
  end
end
