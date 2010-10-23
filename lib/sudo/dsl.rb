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
      sudo_start unless sudo_started?
      @__default_sudo_wrapper[object]
    end
    def sudo_started?
      @__default_sudo_wrapper.running?
    end

  end

end
