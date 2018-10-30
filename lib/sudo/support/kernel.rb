module Kernel
  def wait_for(conf)
    start = Time.now
    defaults = {
      :timeout  => nil,
      :step     => 0.125
    }
    conf = defaults.update conf
    condition = false
    loop do
      condition = yield

      break if    condition
      break if    conf[:timeout] and Time.now - start > conf[:timeout]

      sleep       conf[:step]
    end
    condition
  end
end
