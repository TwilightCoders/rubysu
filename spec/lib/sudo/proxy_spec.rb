require 'spec_helper'

describe Sudo::MethodProxy do
  let(:object) { double('test_object') }
  let(:proxy) { double('proxy') }
  subject { described_class.new(object, proxy) }

  describe '#initialize' do
    it 'stores object and proxy references' do
      method_proxy = described_class.new(object, proxy)
      expect(method_proxy.instance_variable_get(:@object)).to eq(object)
      expect(method_proxy.instance_variable_get(:@proxy)).to eq(proxy)
    end
  end

  describe '#method_missing' do
    it 'delegates method calls to proxy' do
      expect(proxy).to receive(:proxy).with(object, :test_method, 'arg1', 'arg2')
      subject.test_method('arg1', 'arg2')
    end

    it 'supports blocks' do
      block = proc { 'test' }
      expect(proxy).to receive(:proxy).with(object, :test_method, &block)
      subject.test_method(&block)
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true if object responds to method' do
      allow(object).to receive(:respond_to?).with(:test_method, false).and_return(true)
      expect(subject.respond_to?(:test_method)).to be true
    end

    it 'returns false if object does not respond to method' do
      allow(object).to receive(:respond_to?).with(:unknown_method, false).and_return(false)
      expect(subject.respond_to?(:unknown_method)).to be false
    end
  end
end

describe Sudo::Proxy do
  it 'proxies the call' do
    expect(subject.proxy(Kernel)).to eq(Kernel)
  end

  context '#loaded_specs' do
    it 'returns an array of gem names' do
      expect(subject.loaded_specs).to be_a(Array)
      expect(subject.loaded_specs).to_not be_empty
      expect(subject.loaded_specs).to all(be_a(String))
    end

    it 'handles errors gracefully' do
      allow(Gem).to receive(:loaded_specs).and_raise(StandardError.new('test error'))
      allow(subject).to receive(:warn) # Suppress warning output in tests
      expect(subject.loaded_specs).to eq([])
    end
  end

  context '#load_path' do
    it 'returns a list' do
      expect(subject.load_path).to be_a(Array)
    end

    it 'is not empty' do
      expect(subject.load_path).to_not be_empty
    end
  end

  context '#add_load_path' do
    it 'returns a list' do
      expect(subject.add_load_path('foo')).to be_a(Array)
    end

    it 'includes the added path' do
      path = 'bar/bar/bar/barrrrr'
      expect(subject.add_load_path(path)).to include(path)
    end
  end
end
