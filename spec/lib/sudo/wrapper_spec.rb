require 'spec_helper'

describe Sudo::Wrapper do
  subject do
    described_class.run do |sudo|
      sudo[File].open('/etc/hosts', 'r+').close
    end
  end

  describe '#run' do

    it 'raises no error' do
      expect{subject}.to_not raise_error
    end
  end

  describe '#[]' do
    it 'raises an error if not running' do
      allow_any_instance_of(Sudo::Wrapper).to receive(:running?).and_return(false)
      expect{subject}.to raise_error(Sudo::Wrapper::NotRunning)
    end
  end

  describe 'Configuration integration' do
    describe '.run with configuration overrides' do
      it 'creates Configuration with provided overrides' do
        expect(Sudo::Configuration).to receive(:new).with({ timeout: 20, retries: 5 }).and_call_original

        allow_any_instance_of(Sudo::Wrapper).to receive(:start!) { |instance| instance }
        allow_any_instance_of(Sudo::Wrapper).to receive(:stop!)

        described_class.run(timeout: 20, retries: 5) { |sudo| }
      end

      it 'filters unknown configuration options' do
        expect(Sudo::Configuration).to receive(:new).with({ timeout: 15, unknown_option: 'test' }).and_call_original

        allow_any_instance_of(Sudo::Wrapper).to receive(:start!) { |instance| instance }
        allow_any_instance_of(Sudo::Wrapper).to receive(:stop!)

        described_class.run(timeout: 15, unknown_option: 'test') { |sudo| }
      end
    end

    describe '#initialize with configuration' do
      let(:custom_config) { Sudo::Configuration.new(timeout: 30, load_gems: false) }

      it 'uses provided configuration object' do
        wrapper = described_class.new(config: custom_config)
        expect(wrapper.instance_variable_get(:@timeout)).to eq(30)
        expect(wrapper.instance_variable_get(:@load_gems)).to eq(false)
      end

      it 'falls back to global configuration when none provided' do
        Sudo.configure { |c| c.timeout = 45 }
        wrapper = described_class.new
        expect(wrapper.instance_variable_get(:@timeout)).to eq(45)

        Sudo.reset_configuration! # cleanup
      end

      it 'extracts configuration values into instance variables' do
        config = Sudo::Configuration.new(timeout: 25, retries: 7, load_gems: false)
        wrapper = described_class.new(config: config)

        expect(wrapper.instance_variable_get(:@timeout)).to eq(25)
        expect(wrapper.instance_variable_get(:@retries)).to eq(7)
        expect(wrapper.instance_variable_get(:@load_gems)).to eq(false)
      end
    end

    describe 'socket path generation with custom socket_dir' do
      it 'uses configuration socket_dir for socket path' do
        config = Sudo::Configuration.new(socket_dir: '/custom/path')
        wrapper = described_class.new(config: config)

        socket_path = wrapper.instance_variable_get(:@socket)
        expect(socket_path).to start_with('/custom/path/rubysu-')
      end
    end

    describe 'load_gems configuration integration' do
      let(:wrapper) { described_class.new(config: Sudo::Configuration.new(load_gems: false)) }

      it 'respects load_gems false configuration' do
        expect(wrapper.send(:load_gems?)).to eq(false)
      end

      it 'respects load_gems true configuration' do
        wrapper_with_gems = described_class.new(config: Sudo::Configuration.new(load_gems: true))
        expect(wrapper_with_gems.send(:load_gems?)).to eq(true)
      end
    end
  end

end
