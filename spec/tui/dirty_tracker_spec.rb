require 'spec_helper'

RSpec.describe Nylera::TUI::DirtyTracker do
  let(:tracker) { described_class.new }

  describe '#mark_dirty' do
    it 'marks a region as dirty' do
      tracker.mark_dirty(:nav_box)
      expect(tracker.dirty?(:nav_box)).to be true
    end
  end

  describe '#dirty?' do
    it 'returns false for clean regions' do
      expect(tracker.dirty?(:info_box)).to be false
    end

    it 'returns true for dirty regions' do
      tracker.mark_dirty(:info_box)
      expect(tracker.dirty?(:info_box)).to be true
    end
  end

  describe '#content_changed?' do
    it 'returns true for first time content' do
      expect(tracker.content_changed?(:status, 'Playing')).to be true
    end

    it 'returns true when content changes' do
      tracker.content_changed?(:status, 'Playing')
      expect(tracker.content_changed?(:status, 'Paused')).to be true
    end

    it 'returns false for unchanged content' do
      tracker.content_changed?(:status, 'Playing')
      expect(tracker.content_changed?(:status, 'Playing')).to be false
    end
  end

  describe '#clear_dirty' do
    it 'clears dirty flag' do
      tracker.mark_dirty(:nav_box)
      tracker.clear_dirty(:nav_box)
      expect(tracker.dirty?(:nav_box)).to be false
    end
  end

  describe '#mark_all_dirty' do
    it 'marks all regions as dirty' do
      tracker.mark_all_dirty
      expect(tracker.dirty?(:nav_box)).to be true
      expect(tracker.dirty?(:info_box)).to be true
      expect(tracker.dirty?(:progress_bar)).to be true
    end
  end
end
