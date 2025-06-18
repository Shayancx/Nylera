require 'spec_helper'
require 'curses'

RSpec.describe Nylera::TUI::ColorManager do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::ColorManager
      include Curses
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#setup_colors' do
    before do
      allow(instance).to receive(:can_change_color?).and_return(true)
      allow(instance).to receive(:has_colors?).and_return(true)
      allow(instance).to receive(:init_color)
      allow(instance).to receive(:start_color)
      allow(instance).to receive(:init_pair)
    end

    it 'sets up custom colors when supported' do
      expect(instance).to receive(:init_color).at_least(:once)
      expect(instance).to receive(:init_pair).exactly(5).times
      instance.setup_colors
    end

    context 'when colors not supported' do
      before do
        allow(instance).to receive(:can_change_color?).and_return(false)
      end

      it 'does not set up colors' do
        expect(instance).not_to receive(:init_color)
        instance.setup_colors
      end
    end
  end
end
