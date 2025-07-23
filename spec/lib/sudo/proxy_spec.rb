require 'spec_helper'

describe Sudo::Proxy do
  it 'proxies the call' do
    expect(subject.proxy(Kernel)).to eq(Kernel)
  end

  context '#loaded_specs' do

    it 'returns a hash' do
      expect(subject.loaded_specs).to be_a(Hash)
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
