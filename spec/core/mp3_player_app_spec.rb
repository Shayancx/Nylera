require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Nylera::MP3PlayerApp do
  # Skip all tests if MPG123 module not loaded
  before(:all) do
    skip "MPG123 library not available" unless defined?(Nylera::MPG123)
  end
  
  let(:music_dir) { Dir.mktmpdir }
  let(:app) { described_class.new(music_dir) }

  before do
    # Create test MP3 files
    File.write(File.join(music_dir, 'test1.mp3'), 'dummy')
    File.write(File.join(music_dir, 'test2.mp3'), 'dummy')
    
    # Mock MPG123 initialization
    allow(Nylera::MPG123).to receive(:mpg123_init)
    allow(Nylera::MPG123).to receive(:mpg123_exit)
  end

  after do
    FileUtils.rm_rf(music_dir)
  end

  describe '#initialize' do
    it 'loads playlist from music directory' do
      playlist = app.instance_variable_get(:@playlist)
      expect(playlist.size).to eq(2)
      expect(playlist.all? { |f| f.end_with?('.mp3') }).to be true
    end

    it 'initializes MPG123' do
      expect(Nylera::MPG123).to have_received(:mpg123_init)
    end

    context 'with empty directory' do
      let(:empty_dir) { Dir.mktmpdir }
      
      it 'exits with error' do
        expect { described_class.new(empty_dir) }.to raise_error(SystemExit)
      ensure
        FileUtils.rm_rf(empty_dir)
      end
    end
  end

  describe '#handle_action' do
    let(:tui) { double('tui', update: nil, filtered_playlist: app.instance_variable_get(:@playlist)) }

    before do
      app.instance_variable_set(:@tui, tui)
      allow(app).to receive(:toggle_pause)
      allow(app).to receive(:skip)
      allow(app).to receive(:play_track)
    end

    it 'handles pause/resume action' do
      expect(app).to receive(:toggle_pause)
      app.send(:handle_action, :pause_resume)
    end

    it 'handles fast forward action' do
      expect(app).to receive(:skip).with(10)
      app.send(:handle_action, :ff_10sec)
    end

    it 'handles rewind action' do
      expect(app).to receive(:skip).with(-10)
      app.send(:handle_action, :rw_10sec)
    end

    it 'handles track selection' do
      expect(app).to receive(:play_track).with(0)
      app.send(:handle_action, 0)
    end
  end
end
