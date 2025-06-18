require 'spec_helper'

RSpec.describe Nylera::TUI::Utils do
  let(:dummy_class) do
    Class.new do
      include Nylera::TUI::Utils
      attr_accessor :elapsed_time, :elapsed_mutex
      
      def initialize
        @elapsed_time = { seconds: 0.0 }
        @elapsed_mutex = Mutex.new
      end
    end
  end
  
  let(:instance) { dummy_class.new }

  describe '#format_time' do
    it 'formats seconds to MM:SS' do
      expect(instance.format_time(0)).to eq('00:00')
      expect(instance.format_time(59)).to eq('00:59')
      expect(instance.format_time(60)).to eq('01:00')
      expect(instance.format_time(125)).to eq('02:05')
      expect(instance.format_time(3661)).to eq('61:01')
    end
  end

  describe '#safe_utf8_copy' do
    it 'returns empty string for nil' do
      expect(instance.safe_utf8_copy(nil)).to eq('')
    end

    it 'handles valid UTF-8 strings' do
      expect(instance.safe_utf8_copy('Hello')).to eq('Hello')
    end

    it 'replaces invalid UTF-8 characters' do
      invalid_string = "Hello\xC3World"
      result = instance.safe_utf8_copy(invalid_string)
      expect(result).to include('Hello')
      expect(result).to include('?')
    end
  end

  describe '#current_elapsed' do
    it 'returns elapsed time safely' do
      instance.elapsed_time[:seconds] = 42.5
      expect(instance.current_elapsed).to eq(42.5)
    end
  end
end
