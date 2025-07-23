# frozen_string_literal: true

require 'timeout'

# Kernel module extensions for sudo functionality
module Kernel
  def wait_for(timeout: nil, step: 0.125)
    Timeout.timeout(timeout) do
      condition = false
      sleep(step) until (condition = yield)
      condition
    end
  rescue Timeout::Error
    false
  end
end
