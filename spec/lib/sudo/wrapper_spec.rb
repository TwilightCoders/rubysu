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

end
