require 'spec_helper'

describe Process do
  it 'raises no error' do
    expect{Process.exists?(-1)}.to_not raise_error
  end

  it 'returns false if process does not exist' do
    expect(Process.exists?(-1)).to eq(false)
  end

end
