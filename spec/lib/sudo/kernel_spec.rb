require 'spec_helper'

describe Kernel do
  subject do
    described_class.wait_for(timeout: 1) {
      sleep 0.5 until false
    }
  end

  it 'raises a timeout error' do
    expect(subject).to eq(false)
  end

end
