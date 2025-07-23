# frozen_string_literal: true

# Process module extensions for sudo functionality
module Process
  class << self
    # Thanks to:
    # http://stackoverflow.com/questions/141162/how-can-i-determine-if-a-different-process-id-is-running-using-java-or-jruby-on-l
    def exists?(pid)
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH, TypeError
      false
    end
  end
end
