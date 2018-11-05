require 'timeout'

module Kernel
  def wait_for(timeout: nil, step: 0.125)
    Timeout::timeout(timeout) do
      condition = false
      sleep(step) until (condition = yield) and return condition
    end
  rescue Timeout::Error
    return false
  end
end
