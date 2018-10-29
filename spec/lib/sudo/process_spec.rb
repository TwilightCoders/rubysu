require 'spec_helper'

describe Process do
  it 'raises no error' do
    expect{Process.exists?(-1)}.to_not raise_error
  end

  it 'returns false if process does not exist' do
    expect(Process.exists?(-1)).to eq(false)
  end


  it 'can kill what it wants' do
    pid = fork do
      Signal.trap("HUP") { puts "Oof!" }
      Signal.trap("TERM") { puts "Ouch!" }
      sleep 400
       # ... do some work ...
    end

    ["HUP", "TERM", "KILL"].each do |sig|
      puts "#{sig}ing..."
      puts Process.kill(sig, pid)
      # sleep 1
      puts Process.exists?(pid)
    end

    # puts system "kill #{pid}"
    # puts system "kill -9 #{pid}"

    Process.wait
  end

end
