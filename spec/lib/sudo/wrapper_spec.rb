require 'spec_helper'

describe Sudo::Wrapper do

  describe '#run' do
    subject do
      described_class.run do |sudo|
        sudo[File].open('/etc/hosts', 'r+').close
      end
    end

    it 'raises no error' do
      expect{subject}.to_not raise_error
    end
  end

end
