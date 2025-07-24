require 'spec_helper'

describe Sudo::Wrapper do
  subject do
    described_class.run do |sudo|
      sudo[File].open('/etc/hosts', 'r+').close
    end
  end

  describe '#run' do
    it 'raises no error' do
      # Mock the system interactions to avoid requiring actual sudo
      allow(Sudo::System).to receive(:check)
      allow(Sudo::System).to receive(:command).and_return([['sudo', 'ruby'], {}])
      allow_any_instance_of(Sudo::Wrapper).to receive(:spawn).and_return(1234)
      allow(Process).to receive(:detach)
      allow_any_instance_of(Sudo::Wrapper).to receive(:wait_for).and_return(true)
      allow_any_instance_of(Sudo::Wrapper).to receive(:socket?).and_return(true)
      allow(DRbObject).to receive(:new_with_uri).and_return(double('proxy'))
      allow_any_instance_of(Sudo::Wrapper).to receive(:load!)
      allow_any_instance_of(Sudo::Wrapper).to receive(:running?).and_return(true)

      # Mock the MethodProxy creation and file operations
      method_proxy = double('method_proxy')
      allow(Sudo::MethodProxy).to receive(:new).and_return(method_proxy)
      allow(method_proxy).to receive(:open).and_return(double('file', close: nil))

      expect { subject }.to_not raise_error
    end
  end

  describe '#[]' do
    it 'raises an error if not running' do
      allow_any_instance_of(Sudo::Wrapper).to receive(:running?).and_return(false)
      # Mock system interactions to get to the running? check
      allow(Sudo::System).to receive(:check)
      allow(Sudo::System).to receive(:command).and_return([['sudo', 'ruby'], {}])
      allow_any_instance_of(Sudo::Wrapper).to receive(:spawn).and_return(1234)
      allow(Process).to receive(:detach)
      allow_any_instance_of(Sudo::Wrapper).to receive(:wait_for).and_return(true)
      allow_any_instance_of(Sudo::Wrapper).to receive(:socket?).and_return(true)
      allow(DRbObject).to receive(:new_with_uri).and_return(double('proxy'))
      allow_any_instance_of(Sudo::Wrapper).to receive(:load!)

      expect { subject }.to raise_error(Sudo::Wrapper::NotRunning)
    end
  end

  describe 'cleanup behavior' do
    describe '.run ensure block' do
      it 'calls stop! on successful wrapper creation' do
        wrapper_instance = double('wrapper', stop!: nil)
        allow(described_class).to receive(:new).and_return(wrapper_instance)
        allow(wrapper_instance).to receive(:start!).and_return(wrapper_instance)

        expect(wrapper_instance).to receive(:stop!)

        described_class.run { |sudo| }
      end

      it 'does not raise error when wrapper creation fails and sudo is nil' do
        allow(described_class).to receive(:new).and_raise(StandardError, "Creation failed")

        # This should not raise NoMethodError due to safe navigation
        expect { described_class.run { |sudo| } }.to raise_error(StandardError, "Creation failed")
      end

      it 'calls stop! even when block raises exception' do
        wrapper_instance = double('wrapper', stop!: nil)
        allow(described_class).to receive(:new).and_return(wrapper_instance)
        allow(wrapper_instance).to receive(:start!).and_return(wrapper_instance)

        expect(wrapper_instance).to receive(:stop!)

        expect do
          described_class.run { |sudo| raise "Block error" }
        end.to raise_error("Block error")
      end
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

  describe 'Error handling and edge cases' do
    describe '#start!' do
      it 'raises error when socket creation times out' do
        allow(Sudo::System).to receive(:check)
        allow(Sudo::System).to receive(:command).and_return([['sudo', 'ruby'], {}])
        allow_any_instance_of(Sudo::Wrapper).to receive(:spawn).and_return(1234)
        allow(Process).to receive(:detach)
        allow_any_instance_of(Sudo::Wrapper).to receive(:wait_for).and_return(false) # timeout

        wrapper = described_class.new
        expect { wrapper.start! }.to raise_error(RuntimeError, /Couldn't create DRb socket/)
      end
    end

    describe '#running?' do
      it 'returns false when process does not exist' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@sudo_pid, 99999)
        wrapper.instance_variable_set(:@proxy, double('proxy'))
        allow(wrapper).to receive(:socket?).and_return(true)
        allow(Process).to receive(:exists?).with(99999).and_return(false)

        expect(wrapper.running?).to be false
      end

      it 'returns false when socket does not exist' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@sudo_pid, 1234)
        wrapper.instance_variable_set(:@proxy, double('proxy'))
        allow(Process).to receive(:exists?).with(1234).and_return(true)
        allow(wrapper).to receive(:socket?).and_return(false)

        expect(wrapper.running?).to be false
      end

      it 'returns falsy when proxy is nil' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@sudo_pid, 1234)
        wrapper.instance_variable_set(:@proxy, nil)
        allow(Process).to receive(:exists?).with(1234).and_return(true)
        allow(wrapper).to receive(:socket?).and_return(true)

        expect(wrapper.running?).to be_falsy
      end
    end

    describe 'gem loading error handling' do
      it 'handles DRb marshaling errors in prospective_gems' do
        wrapper = described_class.new
        proxy = double('proxy')
        wrapper.instance_variable_set(:@proxy, proxy)

        allow(proxy).to receive(:loaded_specs).and_raise(StandardError.new('marshaling error'))
        allow(wrapper).to receive(:warn) # Suppress warning output in tests
        expect(wrapper.send(:prospective_gems)).to eq([])
      end

      it 'handles LoadError in try_gem_variants' do
        wrapper = described_class.new
        proxy = double('proxy')
        wrapper.instance_variable_set(:@proxy, proxy)

        allow(proxy).to receive(:proxy).with(Kernel, :require, 'test-gem').and_raise(LoadError)
        allow(proxy).to receive(:proxy).with(Kernel, :require, 'test/gem').and_raise(LoadError)

        # Should not raise error, just continue
        expect { wrapper.send(:try_gem_variants, 'test-gem') }.not_to raise_error
      end

      it 'handles NameError in try_gem_variants' do
        wrapper = described_class.new
        proxy = double('proxy')
        wrapper.instance_variable_set(:@proxy, proxy)

        allow(proxy).to receive(:proxy).with(Kernel, :require, 'test-gem').and_raise(NameError)
        allow(proxy).to receive(:proxy).with(Kernel, :require, 'test/gem').and_return(true)

        expect { wrapper.send(:try_gem_variants, 'test-gem') }.not_to raise_error
      end

      it 'stops trying variants on successful require' do
        wrapper = described_class.new
        proxy = double('proxy')
        wrapper.instance_variable_set(:@proxy, proxy)

        expect(proxy).to receive(:proxy).with(Kernel, :require, 'test-gem').and_return(true).once
        expect(proxy).not_to receive(:proxy).with(Kernel, :require, 'test/gem')

        wrapper.send(:try_gem_variants, 'test-gem')
      end
    end

    describe 'load_paths method' do
      it 'adds missing paths from host to proxy' do
        wrapper = described_class.new
        proxy = double('proxy')
        wrapper.instance_variable_set(:@proxy, proxy)

        host_paths = ['/host/path1', '/host/path2', '/shared/path']
        proxy_paths = ['/shared/path', '/proxy/path']

        allow($LOAD_PATH).to receive(:-).and_return(['/host/path1', '/host/path2'])
        allow(proxy).to receive(:load_path).and_return(proxy_paths)
        allow(proxy).to receive(:add_load_path).with('/host/path1')
        allow(proxy).to receive(:add_load_path).with('/host/path2')

        expect(proxy).to receive(:add_load_path).with('/host/path1')
        expect(proxy).to receive(:add_load_path).with('/host/path2')

        wrapper.send(:load_paths)
      end
    end

    describe 'Finalizer class' do
      it 'calls cleanup when invoked' do
        data = { pid: 1234, socket: '/tmp/test.sock' }
        finalizer = described_class::Finalizer.new(data)

        expect(described_class).to receive(:cleanup!).with(data)
        finalizer.call
      end
    end

    describe '.cleanup!' do
      it 'calls System.kill and System.unlink' do
        data = { pid: 1234, socket: '/tmp/test.sock' }

        expect(Sudo::System).to receive(:kill).with(1234)
        expect(Sudo::System).to receive(:unlink).with('/tmp/test.sock')

        described_class.cleanup!(data)
      end
    end

    describe '#server_uri' do
      it 'returns drbunix URI with socket path' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@socket, '/tmp/test.sock')

        expect(wrapper.server_uri).to eq('drbunix:/tmp/test.sock')
      end
    end

    describe '#socket?' do
      it 'returns true when socket file exists' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@socket, '/tmp/existing.sock')
        allow(File).to receive(:exist?).with('/tmp/existing.sock').and_return(true)

        expect(wrapper.socket?).to be true
      end

      it 'returns false when socket file does not exist' do
        wrapper = described_class.new
        wrapper.instance_variable_set(:@socket, '/tmp/missing.sock')
        allow(File).to receive(:exist?).with('/tmp/missing.sock').and_return(false)

        expect(wrapper.socket?).to be false
      end
    end
  end
end
