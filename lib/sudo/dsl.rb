=begin
  DEPRECATED

  It's not clear what the scope of __default_sudo_wrapper should be:
  local, instance, class? global? and what about thread-safety?

=end

=begin
require 'sudo/wrapper'

module Sudo

  module DSL
    def sudo_start(*args, &blk)
      @__default_sudo_wrapper = Sudo::Wrapper.new(*args, &blk).start!
    end
    def sudo_stop
      @__default_sudo_wrapper.stop!
    end
    def sudo(object)
      @__default_sudo_wrapper[object]
    end
  end

end
=end
