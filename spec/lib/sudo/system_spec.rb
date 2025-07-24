require 'spec_helper'

describe Sudo::System do
  context '#unlink' do
    subject do
      described_class.unlink('/tmp/foo')
    end

    it 'deletes file' do
      File.open('/tmp/foo', 'w+')
      expect { subject }.to_not raise_exception
    end

    it 'raises exception if unable to delete file' do
      allow_any_instance_of(Kernel).to receive(:system).and_return(false)
      allow(File).to receive(:exist?).and_return(true)
      expect { described_class.unlink('/tmp/bar') }.to raise_exception(Sudo::System::FileStillExists)
    end
  end
end
