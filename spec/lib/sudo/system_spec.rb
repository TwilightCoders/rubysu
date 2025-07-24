require 'spec_helper'

describe Sudo::System do
  describe '#kill' do
    it 'does nothing if pid is nil' do
      expect(described_class).not_to receive(:system)
      described_class.kill(nil)
    end

    it 'does nothing if process does not exist' do
      allow(Process).to receive(:exists?).with(12345).and_return(false)
      expect(described_class).not_to receive(:system)
      described_class.kill(12345)
    end

    it 'tries kill then kill -9 on failure' do
      allow(Process).to receive(:exists?).with(12345).and_return(true)
      allow(described_class).to receive(:system).with("sudo", "kill", "12345").and_return(false)
      allow(described_class).to receive(:system).with("sudo", "kill", "-9", "12345").and_return(true)

      expect { described_class.kill(12345) }.not_to raise_error
    end

    it 'raises ProcessStillExists if both kill attempts fail' do
      allow(Process).to receive(:exists?).with(12345).and_return(true)
      allow(described_class).to receive(:system).and_return(false)

      expect { described_class.kill(12345) }.to raise_error(Sudo::System::ProcessStillExists)
    end
  end

  describe '#command' do
    it 'builds command array with ruby options and socket' do
      allow(described_class).to receive(:command_base).with({}).and_return([['sudo', '-E', 'ruby'], {}])

      result = described_class.command('-v', '/tmp/socket.sock')
      cmd_args, env = result

      expect(cmd_args).to include('-v')
      expect(cmd_args).to include('/tmp/socket.sock')
      expect(cmd_args).to include(Process.uid.to_s)
    end

    it 'handles empty ruby_opts' do
      allow(described_class).to receive(:command_base).with({}).and_return([['sudo', '-E', 'ruby'], {}])

      result = described_class.command('', '/tmp/socket.sock')
      cmd_args, _ = result

      expect(cmd_args).not_to include('')
    end
  end

  describe '#check' do
    it 'calls sudo with -e flag to check permissions' do
      allow(described_class).to receive(:command_base).and_return([['sudo', '-E', 'ruby'], {}])
      allow(described_class).to receive(:system).with({}, 'sudo', '-E', 'ruby', '-e', '').and_return(true)

      expect { described_class.check }.not_to raise_error
    end

    it 'raises SudoFailed when sudo check fails' do
      allow(described_class).to receive(:command_base).and_return([['sudo', '-E', 'ruby'], {}])
      allow(described_class).to receive(:system).and_return(false)

      expect { described_class.check }.to raise_error(Sudo::Wrapper::SudoFailed)
    end
  end

  describe '#command_base' do
    it 'builds basic command without askpass' do
      cmd_args, env = described_class.send(:command_base)

      expect(cmd_args).to include(Sudo::SUDO_CMD)
      expect(cmd_args).to include('-E')
      expect(env).to be_empty
    end

    it 'adds askpass when configuration is set' do
      allow(Sudo).to receive(:configuration).and_return(double(sudo_askpass: '/usr/bin/ssh-askpass'))

      cmd_args, env = described_class.send(:command_base)

      expect(cmd_args).to include('-A')
      expect(env['SUDO_ASKPASS']).to eq('/usr/bin/ssh-askpass')
    end

    it 'handles custom environment' do
      custom_env = { 'CUSTOM_VAR' => 'value' }
      cmd_args, env = described_class.send(:command_base, custom_env)

      expect(env['CUSTOM_VAR']).to eq('value')
    end
  end

  context '#unlink' do
    subject do
      described_class.unlink('/tmp/foo')
    end

    it 'deletes file' do
      File.open('/tmp/foo', 'w+')
      allow(described_class).to receive(:system).with("sudo", "rm", "-f", '/tmp/foo').and_return(true)
      expect { subject }.to_not raise_exception
    end

    it 'raises exception if unable to delete file' do
      allow_any_instance_of(Kernel).to receive(:system).and_return(false)
      allow(File).to receive(:exist?).and_return(true)
      expect { described_class.unlink('/tmp/bar') }.to raise_exception(Sudo::System::FileStillExists)
    end

    it 'does nothing if file does not exist' do
      allow(File).to receive(:exist?).with('/tmp/nonexistent').and_return(false)
      expect(described_class).not_to receive(:system)
      described_class.unlink('/tmp/nonexistent')
    end

    it 'does nothing if file path is nil' do
      expect(described_class).not_to receive(:system)
      described_class.unlink(nil)
    end
  end
end
