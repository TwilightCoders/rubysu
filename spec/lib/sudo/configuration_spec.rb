# frozen_string_literal: true

require 'spec_helper'

describe Sudo::Configuration do
  let(:config) { Sudo::Configuration.new }

  describe '#initialize' do
    it 'sets default timeout' do
      expect(config.timeout).to eq(10)
    end

    it 'sets default retries' do
      expect(config.retries).to eq(3)
    end

    it 'sets default socket_dir' do
      expect(config.socket_dir).to eq('/tmp')
    end


    it 'sets default sudo_askpass' do
      expect(config.sudo_askpass).to be_nil
    end

    it 'sets default load_gems' do
      expect(config.load_gems).to eq(true)
    end

    context 'with hash parameter' do
      it 'merges provided configuration' do
        config = Sudo::Configuration.new(timeout: 20, retries: 5)
        expect(config.timeout).to eq(20)
        expect(config.retries).to eq(5)
        expect(config.socket_dir).to eq('/tmp') # default preserved
      end

      it 'filters out unknown configuration keys' do
        config = Sudo::Configuration.new(timeout: 15, unknown_key: 'value')
        expect(config.timeout).to eq(15)
        expect(config).not_to respond_to(:unknown_key)
      end
    end

    context 'with keyword arguments' do
      it 'accepts keyword arguments' do
        config = Sudo::Configuration.new(timeout: 25, load_gems: false)
        expect(config.timeout).to eq(25)
        expect(config.load_gems).to eq(false)
      end

      it 'filters out unknown keyword arguments' do
        config = Sudo::Configuration.new(timeout: 30, invalid_option: 'test')
        expect(config.timeout).to eq(30)
        expect(config).not_to respond_to(:invalid_option)
      end
    end

    context 'with both hash and kwargs' do
      it 'merges hash and kwargs with kwargs taking precedence' do
        config = Sudo::Configuration.new({ timeout: 15 }, timeout: 35)
        expect(config.timeout).to eq(35)
      end
    end
  end

  describe 'method_missing behavior' do
    context 'for valid configuration keys' do
      it 'allows getting values via method calls' do
        expect(config.timeout).to eq(10)
        expect(config.retries).to eq(3)
        expect(config.socket_dir).to eq('/tmp')
      end

      it 'allows setting values via method calls' do
        config.timeout = 25
        config.retries = 7
        expect(config.timeout).to eq(25)
        expect(config.retries).to eq(7)
      end

      it 'handles nil values' do
        config.sudo_askpass = nil
        expect(config.sudo_askpass).to be_nil
      end

      it 'handles empty string values' do
        config.socket_dir = ''
        expect(config.socket_dir).to eq('')
      end
    end

    context 'for invalid configuration keys' do
      it 'raises NoMethodError for unknown getters' do
        expect { config.unknown_option }.to raise_error(NoMethodError, /undefined method `unknown_option'/)
      end

      it 'raises NoMethodError for unknown setters' do
        expect { config.unknown_option = 'value' }.to raise_error(NoMethodError, /undefined method `unknown_option='/)
      end
    end
  end

  describe 'respond_to_missing? behavior' do
    it 'returns true for valid configuration keys' do
      expect(config.respond_to?(:timeout)).to be true
      expect(config.respond_to?(:retries)).to be true
      expect(config.respond_to?(:socket_dir)).to be true
      expect(config.respond_to?(:sudo_askpass)).to be true
      expect(config.respond_to?(:load_gems)).to be true
    end

    it 'returns true for valid configuration setters' do
      expect(config.respond_to?(:timeout=)).to be true
      expect(config.respond_to?(:retries=)).to be true
      expect(config.respond_to?(:socket_dir=)).to be true
    end

    it 'returns false for unknown methods' do
      expect(config.respond_to?(:unknown_option)).to be false
      expect(config.respond_to?(:unknown_option=)).to be false
    end
  end

  describe 'Hash inheritance behavior' do
    it 'inherits from Hash' do
      expect(config).to be_a(Hash)
    end

    it 'contains all default values as hash keys' do
      # Since [] is private, we can't directly test hash access
      # Instead test that it behaves like a hash via other methods
      expect(config.keys).to include(:timeout, :retries, :socket_dir, :sudo_askpass, :load_gems)
    end

    it 'updates hash values when using property setters' do
      config.timeout = 50
      expect(config.timeout).to eq(50)
    end

    it 'privatizes direct hash access methods' do
      expect { config[:timeout] }.to raise_error(NoMethodError, /private method/)
      expect { config[:timeout] = 99 }.to raise_error(NoMethodError, /private method/)
    end
  end

  describe '#socket_path' do
    it 'generates socket path with pid and random id' do
      path = config.socket_path(1234, 'abc123')
      expect(path).to eq('/tmp/rubysu-1234-abc123')
    end

    it 'uses custom socket_dir when configured' do
      config.socket_dir = '/var/run'
      path = config.socket_path(1234, 'abc123')
      expect(path).to eq('/var/run/rubysu-1234-abc123')
    end

    context 'edge cases' do
      it 'handles nil pid' do
        path = config.socket_path(nil, 'abc123')
        expect(path).to eq('/tmp/rubysu--abc123')
      end

      it 'handles empty random id' do
        path = config.socket_path(1234, '')
        expect(path).to eq('/tmp/rubysu-1234-')
      end

      it 'handles special characters in random id' do
        path = config.socket_path(1234, 'special/chars')
        expect(path).to eq('/tmp/rubysu-1234-special/chars')
      end

      it 'handles relative socket directory' do
        config.socket_dir = 'relative/path'
        path = config.socket_path(1234, 'abc123')
        expect(path).to eq('relative/path/rubysu-1234-abc123')
      end

      it 'handles empty socket directory' do
        config.socket_dir = ''
        path = config.socket_path(1234, 'abc123')
        expect(path).to eq('/rubysu-1234-abc123')
      end
    end
  end
end

describe Sudo do
  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(Sudo.configuration).to be_a(Sudo::Configuration)
    end

    it 'returns the same instance on multiple calls' do
      expect(Sudo.configuration).to be(Sudo.configuration)
    end
  end

  describe '.configure' do
    before { Sudo.reset_configuration! }
    after { Sudo.reset_configuration! }

    it 'yields the configuration object' do
      Sudo.configure do |config|
        expect(config).to be_a(Sudo::Configuration)
        config.timeout = 20
      end

      expect(Sudo.configuration.timeout).to eq(20)
    end
  end

  describe '.reset_configuration!' do
    it 'resets configuration to defaults' do
      Sudo.configure { |c| c.timeout = 99 }
      expect(Sudo.configuration.timeout).to eq(99)

      Sudo.reset_configuration!
      expect(Sudo.configuration.timeout).to eq(10)
    end
  end

  describe '.as_root' do
    it 'calls Wrapper.run with options' do
      expect(Sudo::Wrapper).to receive(:run).with(timeout: 5)
      Sudo.as_root(timeout: 5) { |sudo| }
    end

    it 'passes multiple configuration options' do
      expect(Sudo::Wrapper).to receive(:run).with(timeout: 30, retries: 7, load_gems: false)
      Sudo.as_root(timeout: 30, retries: 7, load_gems: false) { |sudo| }
    end
  end
end
