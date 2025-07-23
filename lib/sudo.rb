require 'sudo/configuration'
require 'sudo/wrapper'

module Sudo
  # Convenience method for simple root operations
  def self.as_root(**options, &block)
    Wrapper.run(**options, &block)
  end
end
