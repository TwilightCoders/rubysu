module Kernel
  def wait_for(conf)
    start = Time.now
    defaults = {
      :timeout => 2.0
    }
    conf = defaults.update conf
    conf[:step] ||= conf[:timeout] / 20.0
    retval = false
    loop do
      retval = yield
      break if retval
      break if Time.now - start > conf[:timeout]
      sleep conf[:step]
    end
    retval
  end 
end
